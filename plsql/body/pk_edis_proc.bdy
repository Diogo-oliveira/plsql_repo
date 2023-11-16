/*-- Last Change Revision: $Rev: 2027086 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_proc IS

    g_owner_name CONSTANT VARCHAR2(5) := 'ALERT';
    g_pck_name   CONSTANT VARCHAR2(12) := 'PK_EDIS_PROC';

    e_call_exception EXCEPTION;

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_alert_exceptions.error_handling(i_lang, i_func_proc_name, g_pck_name, i_error, i_sqlerror, o_error);
    END error_handling;

    FUNCTION callerror_handler
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_unitname    IN VARCHAR2,
        i_t_error_out IN t_error_out
    ) RETURN t_error_out IS
        l_error_out t_error_out;
        l_error_in  t_error_in := t_error_in();
    
        l_ret BOOLEAN;
    
    BEGIN
        l_error_in.set_all(i_lang, SQLCODE, i_t_error_out.err_desc, g_error, g_owner_name, g_pck_name, i_unitname);
    
        l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
        RETURN l_error_out;
    END callerror_handler;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_arrive) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_transportation,
                   NULL dt_transportation_tstz,
                   NULL id_professional,
                   NULL id_transp_entity,
                   NULL transp_entity,
                   NULL flg_time,
                   NULL notes,
                   NULL id_external_cause,
                   NULL external_cause_desc,
                   NULL id_origin,
                   NULL origin_desc,
                   NULL companion,
                   NULL flg_show_detail,
                   NULL flg_letter,
                   NULL desc_letter,
                   NULL triage_origin_desc,
                   NULL emergency_contact
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    /**********************************************************************************************
    * Retornar os dados para o cabeçalho da aplicação
    *
    * @param i_lang                   the id language
    * @param i_id_pat                 patient id
    * @param i_id_episode             episode id
    * @param i_prof                   professional, software and institution ids
    * @param o_name                   patient name    
    * @param o_gender                 patient gender 
    * @param o_age                    patient age
    * @param o_health_plan            subsistema de saúde do utente. Se houver + do q 1, considera-se o q tiver FLG_DEFAULT = 'S'
    * @param o_compl_pain             Queixa completa             
    * @param o_info_adic              Informação adicional (descrição da categoria + data da última alteração +nome do profissional)
    * @param o_cat_prof               professional category
    * @param o_cat_nurse              nurse category
    * @param o_compl_diag             Diagnosis
    * @param o_prof_name              professional name
    * @param o_nurse_name             nurse name
    * @param o_prof_spec              professional speciality
    * @param o_nurse_spec             nurse speciality
    * @param o_acuity                 acuity
    * @param o_color_text             color text
    * @param o_desc_acuity            acuity description
    * @param o_title_episode          number of episodes title
    * @param o_episode                number of episodes 
    * @param o_title_clin_rec         clin record title
    * @param o_clin_rec               clin record number of the patient
    * @param o_title_location         name of the location where the patient's at title
    * @param o_location               name of the location where the patient's at
    * @param o_title_time_room        title for length of stay
    * @param o_time_room              length of stay of the patient in it's current room
    * @param o_title_admit            title for the admission time field
    * @param o_admit                  date/hour of patient admission in th service
    * @param o_title_total_time       title of the episode duration
    * @param o_total_time             episode duration
    * @param o_pat_photo              patient photo
    * @param o_prof_photo             professional photo
    * @param o_habit                  nº of habit 
    * @param o_allergy                nº of allergy 
    * @param o_prev_epis              nº of previous episode
    * @param o_relev_disease          nº of relevant disease
    * @param o_blood_type             tipo sanguíneo
    * @param o_relev_note             relevant notes
    * @param o_application            application area
    * @param o_info          
    * @param o_nkda                   indicação de "Sem alergias a fármacos"
    * @param o_origin                 Indicação se o episódio advem de um Centro de Saúde
    * @param o_has_adv_directives     Flag that tells if the patient has any advanced directives
    * @param o_adv_directive_sh       Advanced directives shortcut
    * @param o_title_adv_directive    Advanced directives title
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/02
    **********************************************************************************************/
    FUNCTION get_epis_header
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        o_name        OUT patient.name%TYPE,
        o_gender      OUT patient.gender%TYPE,
        o_age         OUT VARCHAR2,
        o_health_plan OUT VARCHAR2,
        o_dbo         OUT VARCHAR2,
        o_compl_pain  OUT VARCHAR2,
        o_info_adic   OUT VARCHAR2,
        o_cat_prof    OUT VARCHAR2,
        o_cat_nurse   OUT VARCHAR2,
        o_compl_diag  OUT VARCHAR2,
        o_prof_name   OUT VARCHAR2,
        o_nurse_name  OUT VARCHAR2,
        o_prof_spec   OUT VARCHAR2,
        o_nurse_spec  OUT VARCHAR2,
        o_acuity      OUT VARCHAR2,
        o_color_text  OUT VARCHAR2,
        o_desc_acuity OUT VARCHAR2,
        --
        o_title_episode    OUT VARCHAR2,
        o_episode          OUT VARCHAR2,
        o_title_clin_rec   OUT VARCHAR2,
        o_clin_rec         OUT VARCHAR2,
        o_title_location   OUT VARCHAR2,
        o_location         OUT VARCHAR2,
        o_title_time_room  OUT VARCHAR2,
        o_time_room        OUT VARCHAR2,
        o_title_admit      OUT VARCHAR2,
        o_admit            OUT VARCHAR2,
        o_title_total_time OUT VARCHAR2,
        o_total_time       OUT VARCHAR2,
        --
        o_pat_photo           OUT VARCHAR2,
        o_prof_photo          OUT VARCHAR2,
        o_habit               OUT VARCHAR2,
        o_allergy             OUT VARCHAR2,
        o_prev_epis           OUT VARCHAR2,
        o_relev_disease       OUT VARCHAR2,
        o_blood_type          OUT VARCHAR2,
        o_relev_note          OUT VARCHAR2,
        o_application         OUT VARCHAR2,
        o_info                OUT VARCHAR2,
        o_nkda                OUT VARCHAR2,
        o_origin              OUT VARCHAR2,
        o_has_adv_directives  OUT VARCHAR2,
        o_adv_directive_sh    OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_title_adv_directive OUT VARCHAR2,
        o_icon_fast_track     OUT VARCHAR2,
        o_desc_fast_track     OUT VARCHAR2,
        o_flg_status          OUT episode.flg_status%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_instit_epis       institution.id_institution%TYPE;
        l_inst_abbr         institution.abbreviation%TYPE;
        l_health_plan       pk_translation.t_desc_translation;
        l_epis_type         epis_type.id_epis_type%TYPE;
        l_id_episode        epis_info.id_episode%TYPE;
        l_dt_efectiv        VARCHAR2(200);
        l_dt_atend          VARCHAR2(200);
        l_months            NUMBER;
        l_days              NUMBER;
        l_age               NUMBER;
        l_id_prof           professional.id_professional%TYPE;
        l_id_nurse          professional.id_professional%TYPE;
        l_prof_spec         VARCHAR2(200);
        l_nurse_spec        VARCHAR2(200);
        l_habit_cnt         PLS_INTEGER;
        l_allergy_cnt       PLS_INTEGER;
        l_all_prev_epis     PLS_INTEGER;
        l_prev_epis_cnt     PLS_INTEGER;
        l_notes_cnt         PLS_INTEGER;
        l_relev_disease_cnt PLS_INTEGER;
        l_blood_group       pat_blood_group.flg_blood_group%TYPE;
        l_blood_rhesus      VARCHAR2(20);
        l_blood_other       VARCHAR2(200);
        l_clin_serv         VARCHAR2(200);
        l_num_health_plan   pat_health_plan.num_health_plan%TYPE;
        l_pat_hplan         pat_health_plan.id_pat_health_plan%TYPE;
        --
        l_desc_anamnesis   epis_anamnesis.desc_epis_anamnesis%TYPE;
        l_anamnesis_prof   VARCHAR2(4000);
        l_triage_nurse     epis_triage.id_triage_nurse%TYPE;
        l_manchester       epis_triage.id_triage%TYPE;
        l_recm             recm.flg_recm%TYPE;
        l_pat              patient.id_patient%TYPE;
        l_show_health_plan sys_config.value%TYPE;
        l_desc_triage      VARCHAR2(2000);
        l_triage_prof      VARCHAR2(2000);
        l_preg_weeks       VARCHAR2(200);
        l_prof_cat         category.flg_type%TYPE;
        l_desc_blood_group sys_message.desc_message%TYPE;
        l_msg_last_change  sys_message.desc_message%TYPE;
        l_origin_temp      sys_message.desc_message%TYPE;
        l_diags            table_varchar;
        l_found            BOOLEAN;
        l_fast_track       fast_track.id_fast_track%TYPE;
        l_num              NUMBER;
        l_show_dbo         sys_config.value%TYPE;
        l_dt_birth         patient.dt_birth%TYPE;
        --
        /*
        Nome do utente,
        subsistema de saúde,
        plano de saude - NUM_HEALTH_PLAN
        nº processo clínico - NUM_CLIN_RECORD
        tipo sanguíneo
        sexo/idade
        */
        CURSOR c_name IS
            SELECT pat.name,
                   pk_translation.get_translation(i_lang, 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) desc_health_plan,
                   nvl((SELECT crn.num_clin_record
                         FROM clin_record crn
                        WHERE crn.id_patient = pat.id_patient
                          AND crn.id_institution = nvl(l_instit_epis, i_prof.institution)
                          AND rownum < 2),
                       '---') num_clin_record,
                   pk_patient.get_gender(i_lang, pat.gender) gender,
                   months_between(SYSDATE, pat.dt_birth) months,
                   (SYSDATE - pat.dt_birth) days,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, NULL, NULL) patphoto,
                   pbg.flg_blood_group,
                   pk_sysdomain.get_domain('PAT_BLOOD_GROUP.FLG_BLOOD_RHESUS', pbg.flg_blood_rhesus, i_lang) flg_blood_rhesus,
                   decode(pbg.desc_other_system, '', '', l_desc_blood_group) desc_blood_group,
                   php.num_health_plan,
                   nvl(trunc(months_between(SYSDATE, pat.dt_birth) / 12, 0), pat.age) age,
                   pat.dt_birth dt_birth
              FROM patient pat,
                   (SELECT *
                      FROM pat_blood_group pg2
                     WHERE pg2.id_patient = i_id_pat
                       AND pg2.flg_status = g_pat_blood_active
                     ORDER BY pg2.dt_pat_blood_group_tstz DESC) pbg,
                   (SELECT *
                      FROM pat_health_plan ph2
                     WHERE ph2.id_patient = i_id_pat
                       AND ph2.flg_status = g_hplan_active
                       AND ph2.flg_default = g_default_hplan_y
                       AND ph2.id_institution = i_prof.institution) php
             WHERE pat.id_patient = i_id_pat
               AND pat.id_patient = pbg.id_patient(+)
               AND pat.id_patient = php.id_patient(+);
    
        CURSOR c_epis IS
            SELECT ei.triage_acuity acuity,
                   ei.triage_color_text color_text,
                   pk_translation.get_translation_dtchk(i_lang,
                                                        'TRIAGE_NURSE.CODE_TRIAGE_NURSE.' || etr.id_triage_nurse) desc_triage,
                   ei.id_episode,
                   p.id_professional,
                   p.name name_prof,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, epis.id_patient, epis.id_episode, ei.id_schedule) patphoto,
                   pn.id_professional prof_nurse,
                   pn.name name_nurse,
                   nvl(nvl(r.desc_room_abbreviation,
                           pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ABBREVIATION.' || ei.id_room)),
                       nvl(r.desc_room, pk_translation.get_translation_dtchk(i_lang, 'ROOM.CODE_ROOM.' || ei.id_room))) desc_room,
                   pk_translation.get_translation_dtchk(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality) desc_spec_prof,
                   pk_translation.get_translation_dtchk(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || pn.id_speciality) desc_spec_nurse,
                   pk_translation.get_translation_dtchk(i_lang,
                                                        'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                        epis.id_clinical_service) clin_serv,
                   epis.id_institution instit,
                   (SELECT decode(i.abbreviation, NULL, NULL, '; ' || i.abbreviation)
                      FROM institution i
                     WHERE i.id_institution = epis.id_institution) abbrev_inst,
                   (SELECT ehp.id_pat_health_plan
                      FROM epis_health_plan ehp
                     WHERE ehp.id_episode = epis.id_episode) id_pat_health_plan,
                   epis.id_epis_type,
                   pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz, nvl(epis.dt_end_tstz, g_sysdate_tstz)) total_time,
                   pk_date_utils.dt_hour_chr_short_tsz(i_lang, epis.dt_begin_tstz, i_prof) admit,
                   etr.id_triage_nurse,
                   etr.id_triage,
                   epis.id_fast_track,
                   epis.flg_status
              FROM (SELECT ep.*,
                           (SELECT id_epis_triage
                              FROM (SELECT etr2.id_epis_triage, etr2.id_episode
                                      FROM epis_triage etr2
                                     ORDER BY etr2.dt_end_tstz DESC) etr
                             WHERE etr.id_episode = ep.id_episode
                               AND rownum < 2) id_epis_triage
                      FROM episode ep
                     WHERE ep.id_episode = i_id_episode) epis,
                   epis_info ei,
                   professional p,
                   professional pn,
                   epis_triage etr,
                   room r
             WHERE epis.id_episode = i_id_episode
               AND epis.id_episode = ei.id_episode
               AND p.id_professional(+) = ei.id_professional
               AND pn.id_professional(+) = ei.id_first_nurse_resp
               AND etr.id_epis_triage(+) = epis.id_epis_triage
               AND ei.id_room = r.id_room(+);
    
        -- Movimentos (para tempo de sala)
    
        --Médico de família
        CURSOR c_fam_prof IS
            SELECT pfp.id_professional, p.nick_name
              FROM pat_family_prof pfp, professional p
             WHERE pfp.id_patient = i_id_pat
               AND pfp.id_institution = i_prof.institution
               AND pfp.dt_end_tstz IS NULL
               AND p.id_professional = pfp.id_professional
               AND pfp.flg_status = pk_alert_constant.g_active;
    
        r_fam_prof c_fam_prof%ROWTYPE;
    
        -- Reaberto / com alta médica (pendente)  Teresa Coutinho 29/06/2007      
        CURSOR c_discharge_status IS
            SELECT decode(d.flg_status,
                          g_discharge_flg_status_pend,
                          decode(i_prof.software,
                                 g_soft_triage,
                                 decode(d.flg_type_disch,
                                        g_discharge_disch_type_triage,
                                        pk_message.get_message(i_lang, 'HEADER_M016'),
                                        pk_message.get_message(i_lang, 'HEADER_M010')),
                                 pk_message.get_message(i_lang, 'HEADER_M010')),
                          g_discharge_flg_status_reopen,
                          pk_message.get_message(i_lang, 'HEADER_M011')) discharge_status
              FROM discharge d
             WHERE d.id_episode = i_id_episode
               AND flg_status IN (g_discharge_flg_status_pend, g_discharge_flg_status_reopen);
    
        e_cname_norows EXCEPTION;
    
        l_error VARCHAR2(4000);
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error            := 'GET CONFIGURATIONS';
        l_desc_blood_group := pk_message.get_message(i_lang, 'HEADER_BLOOD');
    
        o_title_clin_rec      := pk_message.get_message(i_lang, 'EDIS_ID_T002');
        o_title_episode       := pk_message.get_message(i_lang, 'EDIS_ID_T001');
        o_title_location      := pk_message.get_message(i_lang, 'EDIS_ID_T006');
        o_title_time_room     := pk_message.get_message(i_lang, 'EDIS_ID_T008');
        o_title_admit         := pk_message.get_message(i_lang, 'EDIS_ID_T009');
        o_title_total_time    := pk_message.get_message(i_lang, 'EDIS_ID_T010');
        o_title_adv_directive := pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M001');
        l_msg_last_change     := pk_message.get_message(i_lang, 'EDIS_IDENT_T001');
    
        l_prof_cat := pk_tools.get_prof_cat(i_prof);
    
        -- Tipo de episódio (Urg, CE, BO, ...)
        g_error := 'GET CURSOR C_EPIS';
        OPEN c_epis;
        FETCH c_epis
            INTO o_acuity,
                 o_color_text,
                 o_desc_acuity,
                 l_id_episode,
                 l_id_prof,
                 o_prof_name,
                 o_prof_photo,
                 l_id_nurse,
                 o_nurse_name,
                 o_location,
                 l_prof_spec,
                 l_nurse_spec,
                 l_clin_serv,
                 l_instit_epis,
                 l_inst_abbr,
                 l_pat_hplan,
                 l_epis_type,
                 o_total_time,
                 o_admit,
                 l_triage_nurse,
                 l_manchester,
                 l_fast_track,
                 o_flg_status;
        CLOSE c_epis;
    
        g_error := 'CHECK TRANSFER EPIS';
        BEGIN
            SELECT 0
              INTO l_num
              FROM transfer_institution ti
             WHERE ti.id_episode = i_id_episode
               AND ti.flg_status = g_transfer_inst_transp;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'EPISODE WITHOUT ROOM';
        IF l_num = 0
        THEN
            o_location := '---';
        END IF;
    
        BEGIN
            g_error := 'GET MOVEMENT';
            SELECT pk_date_utils.get_elapsed_tsz(i_lang,
                                                 nvl((SELECT MAX(m.dt_end_tstz)
                                                       FROM movement m
                                                      WHERE m.id_episode = i_id_episode
                                                        AND m.flg_status != g_cancelled),
                                                     e.dt_begin_tstz),
                                                 nvl(e.dt_end_tstz, g_sysdate_tstz))
              INTO o_time_room
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        --
        IF i_prof.software = g_soft_care
        THEN
            -- médico de família
            g_error := 'GET C_FAM_PROF';
            OPEN c_fam_prof;
            FETCH c_fam_prof
                INTO r_fam_prof;
            l_found := c_fam_prof%FOUND;
            CLOSE c_fam_prof;
            --
            --É MÉDICO DE FAMíLIA
            IF l_found
            THEN
                g_error := 'GET O_PROF_SPEC';
                IF nvl(l_id_prof, 0) != 0
                   AND l_id_prof = r_fam_prof.id_professional
                THEN
                    o_prof_spec := ' (' || pk_message.get_message(i_lang, 'HEADER_M005') || ')';
                ELSE
                    o_prof_spec := ' (' || pk_message.get_message(i_lang, 'HEADER_M005') || ': ' ||
                                   r_fam_prof.nick_name || l_inst_abbr || ')';
                END IF;
            END IF;
        
        ELSIF l_prof_spec IS NOT NULL
        THEN
            g_error     := 'GET PROF SPEC (H)';
            o_prof_spec := ' (' || l_prof_spec || l_inst_abbr || ')';
        END IF;
        --
        IF l_nurse_spec IS NOT NULL
        THEN
            g_error      := 'GET NURSE SPEC';
            o_nurse_spec := ' (' || l_nurse_spec || l_inst_abbr || ')';
        END IF;
    
        -- pessoal não clinico não vê queixa nem diagnostico
        IF l_prof_cat IN (g_prof_cat_doctor, g_prof_cat_nurse, g_prof_cat_manchester)
        THEN
            -- DIAGNÓSTICOS
            g_error := 'OPEN C_DIAGNOSIS';
            -- FORMATS DIAGNOSES FOR PRESENTATION AND CORRECTLY SORTS THEM 
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => ed2.desc_epis_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => ed2.id_epis_diagnosis) desc_diagnosis
              BULK COLLECT
              INTO l_diags
              FROM ( -- SELECTS THE DIAGNOSES TO SHOW
                    SELECT ed.*,
                            row_number() over(PARTITION BY ed.id_diagnosis ORDER BY decode(ed.flg_type, g_epis_diag_type_definitive, 0, 1) ASC, decode(ed.flg_status, g_epis_diag_confirmed, 0, 1) ASC, decode(ed.flg_status, g_epis_diag_despiste, ed.dt_epis_diagnosis_tstz, ed.dt_confirmed_tstz) DESC) rn
                      FROM epis_diagnosis ed
                     WHERE ed.id_episode = i_id_episode
                       AND ed.flg_status IN (g_epis_diag_confirmed, g_epis_diag_despiste)) ed2
              JOIN diagnosis d
                ON (d.id_diagnosis = ed2.id_diagnosis)
              LEFT JOIN alert_diagnosis ad
                ON ad.id_alert_diagnosis = ed2.id_alert_diagnosis
             WHERE ed2.rn = 1
             ORDER BY decode(ed2.flg_type, g_epis_diag_type_definitive, 0, 1) ASC,
                      decode(ed2.flg_final_type, g_epis_diag_final_type_primary, 0, g_epis_diag_final_type_sec, 1, 2),
                      decode(ed2.flg_status, g_epis_diag_confirmed, 0, 1) ASC;
        
            IF l_diags.count > 0
            THEN
                --tem diagnosticos
                o_compl_diag := pk_utils.concat_table(l_diags, ';');
                SELECT (SELECT nvl(p.nick_name, p.name)
                          FROM professional p
                         WHERE t.id_professional = p.id_professional) || ';' ||
                       pk_date_utils.date_time_chr_tsz(i_lang, t.dt_status_tstz, i_prof)
                  INTO o_info_adic
                  FROM (SELECT decode(ed.flg_status, g_epis_diag_despiste, ed.id_professional_diag, ed.id_prof_confirmed) id_professional,
                               decode(ed.flg_status,
                                      g_epis_diag_despiste,
                                      ed.dt_epis_diagnosis_tstz,
                                      ed.dt_confirmed_tstz) dt_status_tstz
                          FROM epis_diagnosis ed
                         WHERE ed.id_episode = i_id_episode
                           AND ed.flg_status IN (g_epis_diag_confirmed, g_epis_diag_despiste)
                         ORDER BY dt_status_tstz DESC) t
                 WHERE rownum < 2;
                o_info_adic := '(' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || o_info_adic || ')';
            ELSE
                -- não tem diagnostico, então procura-se queixa e triagem
                BEGIN
                    g_error := 'GET COMPLAINT';
                    SELECT desc_compl,
                           (SELECT nvl(p.nick_name, p.name)
                              FROM professional p
                             WHERE t.id_professional = p.id_professional) || ';' ||
                           pk_date_utils.date_time_chr_tsz(i_lang, t.dt_last, i_prof) prof_desc
                      INTO l_desc_anamnesis, l_anamnesis_prof
                      FROM (SELECT pk_translation.get_translation(i_lang, 'COMPLAINT.CODE_COMPLAINT.' || ec.id_complaint) ||
                                   nvl2(ec.patient_complaint, ' (' || ec.patient_complaint || ')', '') desc_compl,
                                   ec.adw_last_update_tstz dt_last,
                                   id_professional
                              FROM epis_complaint ec
                             WHERE ec.id_episode = i_id_episode
                               AND ec.flg_status = g_epis_complaint_active
                            UNION ALL
                            SELECT pk_string_utils.clob_to_sqlvarchar2(ea.desc_epis_anamnesis) desc_compl,
                                   ea.dt_epis_anamnesis_tstz dt_last,
                                   id_professional
                              FROM epis_anamnesis ea
                             WHERE ea.id_episode = i_id_episode
                               AND ea.flg_type = g_epis_anam_type_complaint
                               AND ea.flg_status = g_epis_anam_status_active
                             ORDER BY dt_last DESC) t
                     WHERE rownum < 2;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                -- Triagem
                BEGIN
                    g_error := 'GET TRIAGE';
                    SELECT nvl2(e.id_triage_white_reason,
                                pk_translation.get_translation(i_lang,
                                                               'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                               e.id_triage_white_reason) || ': ' || e.notes,
                                (SELECT pk_translation.get_translation(i_lang,
                                                                       'TRIAGE_BOARD.CODE_TRIAGE_BOARD.' ||
                                                                       t.id_triage_board) || ': ' ||
                                        pk_translation.get_translation(i_lang,
                                                                       'TRIAGE_DISCRIMINATOR.CODE_TRIAGE_DISCRIMINATOR.' ||
                                                                       t.id_triage_discriminator)
                                   FROM triage t
                                  WHERE e.id_triage = t.id_triage)) desc_triage,
                           (SELECT nvl(p.nick_name, p.name)
                              FROM professional p
                             WHERE e.id_professional = p.id_professional) || ';' ||
                           pk_date_utils.date_time_chr_tsz(i_lang, e.dt_end_tstz, i_prof) triage_prof
                      INTO l_desc_triage, l_triage_prof
                      FROM (SELECT etr.id_triage,
                                   etr.id_triage_white_reason,
                                   etr.id_professional,
                                   etr.dt_end_tstz,
                                   etr.notes
                              FROM epis_triage etr
                             WHERE etr.id_episode = i_id_episode
                             ORDER BY etr.dt_begin_tstz DESC) e
                     WHERE rownum < 2;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                IF l_desc_anamnesis IS NOT NULL
                THEN
                    IF l_desc_triage IS NULL
                    THEN
                        o_compl_pain := l_desc_anamnesis;
                        o_info_adic  := '(' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || l_anamnesis_prof || ')';
                    ELSE
                        o_compl_pain := l_desc_anamnesis || ' - ' || l_desc_triage;
                        o_info_adic  := '(' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || l_triage_prof || ')';
                    END IF;
                ELSIF l_desc_triage IS NOT NULL
                THEN
                    --Sem diagnóstico e sem queixa, apenas com triagem
                    o_compl_pain := l_desc_triage;
                    o_info_adic  := '(' || pk_message.get_message(i_lang, 'EDIS_IDENT_T001') || l_triage_prof || ')';
                END IF;
            END IF;
        END IF;
        --        
        g_error := 'GET NKDA TEXT';
        IF NOT pk_episode.get_nkda_label(i_lang, i_prof, i_id_pat, o_nkda, o_error)
        THEN
            RAISE e_call_exception;
        END IF;
        --
        g_error := 'OPEN C_PAT_RECM';
        BEGIN
            SELECT flg_recm
              INTO l_recm
              FROM (SELECT r.flg_recm
                      FROM pat_cli_attributes pca, recm r
                     WHERE pca.id_patient = i_id_pat
                       AND pca.id_recm = r.id_recm
                     ORDER BY pca.adw_last_update DESC)
             WHERE rownum = 1;
        
            IF o_nkda IS NULL
               AND l_recm IS NOT NULL
            THEN
                o_nkda := pk_message.get_message(i_lang, 'IDENT_PATIENT_T023') || ' - ' || l_recm;
            ELSIF o_nkda IS NOT NULL
                  AND l_recm IS NOT NULL
            THEN
                o_nkda := o_nkda || ' / ' || pk_message.get_message(i_lang, 'IDENT_PATIENT_T023') || ' - ' || l_recm;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- Contagem de hábitos
        g_error := 'GET HABIT';
        SELECT COUNT(0)
          INTO l_habit_cnt
          FROM pat_habit
         WHERE id_patient = i_id_pat
           AND flg_status != g_cancelled;
    
        IF l_habit_cnt = 1
        THEN
            o_habit := l_habit_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M001');
        ELSIF l_habit_cnt > 1
        THEN
            o_habit := l_habit_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M002');
        END IF;
    
        -- Contagem de alergias
        g_error       := 'GET ALLERGY';
        l_allergy_cnt := pk_allergy.get_count_allergy(i_lang, i_id_pat, o_error);
    
        IF l_allergy_cnt = 1
        THEN
            o_allergy := l_allergy_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M003');
        ELSIF l_allergy_cnt > 1
        THEN
            o_allergy := l_allergy_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M004');
        END IF;
    
        -- Contagem de doenças relevantes
        g_error := 'GET DISEASE';
        SELECT COUNT(*)
          INTO l_relev_disease_cnt
          FROM pat_history_diagnosis
         WHERE id_patient = i_id_pat
           AND id_alert_diagnosis IS NOT NULL
           AND id_pat_history_diagnosis =
               pk_problems.get_pat_hist_diag_recent(i_lang,
                                                    id_alert_diagnosis,
                                                    NULL,
                                                    i_id_pat,
                                                    i_prof,
                                                    g_pat_history_diagnosis_n);
    
        IF l_relev_disease_cnt = 1
        THEN
            o_relev_disease := l_relev_disease_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M005');
        ELSIF l_relev_disease_cnt > 1
        THEN
            o_relev_disease := l_relev_disease_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M006');
        END IF;
    
        -- Contagem de notas relevantes
        g_error := 'GET NOTES';
        SELECT COUNT(0)
          INTO l_notes_cnt
          FROM v_pat_notes
         WHERE id_patient = i_id_pat
           AND flg_status != g_cancelled;
        --
        IF l_notes_cnt = 1
        THEN
            o_relev_note := l_notes_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M007');
        ELSIF l_notes_cnt > 1
        THEN
            o_relev_note := l_notes_cnt || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M008');
        END IF;
    
        --Tipo de episódio
        IF l_epis_type = g_epis_type_edis
        THEN
            -- urgência
            o_application := pk_message.get_message(i_lang, 'HEADER_M007');
        END IF;
        --
        g_error := 'COUNT PREV EPIS';
        SELECT COUNT(0)
          INTO l_all_prev_epis
          FROM episode e
         WHERE e.id_patient = i_id_pat
           AND e.flg_status IN (g_epis_inactive, g_epis_pending);
    
        l_prev_epis_cnt := pk_edis_proc.get_prev_episode(i_lang, l_pat, i_prof.institution, i_prof.software) +
                           l_all_prev_epis;
        --
        IF l_prev_epis_cnt = 1
        THEN
            o_prev_epis := to_char(l_prev_epis_cnt) || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M009');
        ELSIF l_prev_epis_cnt > 1
        THEN
            o_prev_epis := to_char(l_prev_epis_cnt) || ' ' || pk_message.get_message(i_lang, 'EDIS_ID_M010');
        END IF;
        --
        -- Nome do utente, subsistema de saúde, nº processo clínico, sexo, idade e data de nascimento
        g_error := 'GET CURSOR C_NAME ';
        OPEN c_name;
        FETCH c_name
            INTO o_name,
                 l_health_plan,
                 o_clin_rec,
                 o_gender,
                 l_months,
                 l_days,
                 o_pat_photo,
                 l_blood_group,
                 l_blood_rhesus,
                 l_blood_other,
                 l_num_health_plan,
                 l_age,
                 l_dt_birth;
        l_found := c_name%NOTFOUND;
        CLOSE c_name;
        --
        IF l_found
        THEN
            RAISE e_cname_norows;
        ELSE
            g_error := 'GET BLOOD TYPE';
            IF l_blood_group IS NULL
            THEN
                o_blood_type := NULL;
            ELSE
                o_blood_type := l_blood_group || ' ' || l_blood_rhesus || ' ' || l_blood_other;
            END IF;
            --
            -- É para mostrar o plano de saúde?
            g_error            := 'GET SYS CONFIG SHOW_HEALTH_PLAN_HEADER';
            l_show_health_plan := nvl(pk_sysconfig.get_config('SHOW_HEALTH_PLAN_HEADER', i_prof), g_yes);
            --
            --seguro de saúde
            IF l_show_health_plan = 'Y'
            THEN
                g_error := 'GET HEALTH PLAN';
                BEGIN
                    SELECT ' (' || php.num_health_plan || ' - ' ||
                           pk_translation.get_translation(i_lang, 'HEALTH_PLAN.CODE_HEALTH_PLAN.' || php.id_health_plan) || ')' desc_hplan
                      INTO o_health_plan
                      FROM pat_health_plan php, epis_health_plan ehp
                     WHERE php.id_patient = i_id_pat
                       AND php.id_institution = i_prof.institution
                       AND php.flg_status = g_hplan_active
                       AND php.id_pat_health_plan = ehp.id_pat_health_plan
                       AND ehp.id_episode = i_id_episode
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            ELSE
                --
                -- É para mostrar a data de nascimento?
                g_error    := 'GET SYS CONFIG SHOW_DT_BIRTH_HEADER';
                l_show_dbo := nvl(pk_sysconfig.get_config('SHOW_DT_BIRTH_HEADER', i_prof), g_yes);
                --
                IF l_show_dbo = 'Y'
                   AND l_dt_birth IS NOT NULL
                THEN
                    o_dbo := pk_message.get_message(i_lang => i_lang, i_code_mess => 'HEADER_M017') || ' ' ||
                             pk_date_utils.date_chr_short_read(i_lang => i_lang, i_date => l_dt_birth, i_prof => i_prof);
                END IF;
            END IF;
            --
            g_error := 'GET AGE';
            o_age   := pk_patient.get_pat_age(i_lang, i_id_pat, i_prof);
        END IF;
        --
        -- Header must show the weeks of pregnancy, if the patient has as active one
        IF nvl(pk_sysconfig.get_config('WOMAN_HEALTH_HEADER', i_prof), 'N') = 'Y'
        THEN
            g_error := 'GET PREGNANCY WEEKS';
            IF NOT pk_woman_health.get_pregnancy_weeks(i_lang, i_prof, i_id_pat, l_preg_weeks, o_error)
            THEN
                RAISE e_call_exception;
            END IF;
            IF l_preg_weeks IS NOT NULL
               AND o_age IS NOT NULL
            THEN
                o_age := o_age || ' / ' || l_preg_weeks;
            END IF;
        END IF;
        --    
        --Retornar nº do epis do Sonho,
        g_error := 'CALL TO GET_EPIS_EXT';
        IF NOT pk_episode.get_epis_ext(i_lang       => i_lang,
                                       i_id_episode => l_id_episode,
                                       i_prof       => i_prof,
                                       o_dt_efectiv => l_dt_efectiv,
                                       o_dt_atend   => l_dt_atend,
                                       o_episode    => o_episode,
                                       o_error      => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        -- Origem do episódio
        g_error := 'GET CURSOR C_ORIGIN';
        IF i_prof.software IN (g_soft_edis, g_soft_ubu, g_soft_triage)
        THEN
            OPEN c_discharge_status;
            FETCH c_discharge_status
                INTO o_origin;
            CLOSE c_discharge_status;
            --        
            IF o_origin IS NULL
               AND pk_ubu.get_episode_transportation(i_id_episode, i_prof) IS NOT NULL
            THEN
                o_origin := pk_message.get_message(i_lang, 'HEADER_M009');
            ELSE
                l_origin_temp := pk_transfer_institution.get_inst_transfer_message(i_lang, i_prof, i_id_episode);
                -- Se tiver origem noutra instituição mostra senão mostra estado da alta se a tiver
                IF (l_origin_temp IS NOT NULL)
                THEN
                    o_origin := l_origin_temp;
                END IF;
            END IF;
        END IF;
    
        g_error := 'CALL GET_HAS_PAT_ADV_DIRECTIVE';
        IF NOT pk_advanced_directives.get_adv_directives_for_header(i_lang,
                                                                    i_prof,
                                                                    i_id_pat,
                                                                    i_id_episode,
                                                                    o_has_adv_directives,
                                                                    o_adv_directive_sh,
                                                                    o_error)
        THEN
            RAISE e_call_exception;
        END IF;
    
        g_error           := 'GET FAST TRACK INFO';
        o_icon_fast_track := pk_fast_track.get_fast_track_icon(i_lang, i_prof, l_fast_track, g_icon_ft);
        o_desc_fast_track := pk_fast_track.get_fast_track_desc(i_lang, i_prof, l_fast_track, g_desc_header);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_cname_norows THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                l_error_in.set_errors(SQLCODE, 'c_name no rows', g_error);
            
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id(g_owner_name, g_pck_name, 'GET_EPIS_HEADER');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_HEADER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para pessoal clínico (médicos e enfermeiros)
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category   
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_flg_disch_pend         flag que determina se a alta pendente aparece ou nao na grelha
                                               N- aparece tranportes Y- pararece a alta pendente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/05
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_disch_pend  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        l_from       VARCHAR2(32767);
        l_hint       VARCHAR2(32767);
        l_pat_return t_coll_patcriteriaactiveclin := t_coll_patcriteriaactiveclin();
    BEGIN
    
        o_flg_show := 'N';
        g_sysdate  := SYSDATE;
        --
        l_where := NULL;
        --
        g_error := 'GET WHERE';
        IF (NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                    i_crit_val => i_crit_val,
                                    i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    o_where    => l_where))
        THEN
            l_where := NULL;
        END IF;
        --
        g_error := 'GET FROM';
        IF (NOT pk_search.get_from(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   o_from     => l_from,
                                   o_hint     => l_hint))
        THEN
            l_from := NULL;
        END IF;
        --
        g_error      := 'CONCAT CURSOR O_PAT';
        g_no_results := FALSE;
        g_overlimit  := FALSE;
        --        
    
        l_pat_return := pk_edis_proc.tf_pat_criteria_active_clin(i_lang, i_prof, l_where, l_from, l_hint);
    
        OPEN o_pat FOR
            SELECT *
              FROM TABLE(l_pat_return);
    
        IF (g_no_results = TRUE)
        THEN
            RAISE pk_search.e_noresults;
        END IF;
        IF (g_overlimit = TRUE)
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        o_flg_disch_pend := 'N';
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_criteria_active_clin;


    FUNCTION tf_pat_criteria_active_clin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_patcriteriaactiveclin IS
        l_soft_edis     software.id_software%TYPE;
        dataset         pk_types.cursor_type;
        l_limit         sys_config.desc_sys_config%TYPE;
        l_sysdate_char  VARCHAR2(32);
        l_prof_cat      category.flg_type%TYPE;
        l_show_inp_epis sys_config.value%TYPE;
        l_hand_off_type sys_config.value%TYPE;
        l_supplies      grid_task.supplies%TYPE;
        l_ft_type       fast_track.icon%TYPE;
        l_room_desc     room.desc_room%TYPE;
        l_opinion_state grid_task.opinion_state%TYPE;
    
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_only_epis_resp sys_config.value%TYPE;
    
        l_show_resident_physician sys_config.value%TYPE;
    
        l_query VARCHAR2(32767);
    
        out_obj t_rec_patcriteriaactiveclin;
    
        CURSOR l_cur IS
            SELECT 1 position, t.*
              FROM v_src_edis_active_clin t;
    
        TYPE dataset_tt IS TABLE OF l_cur%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset dataset_tt;
        l_row     PLS_INTEGER := 1;
    
        RESULT t_coll_patcriteriaactiveclin := t_coll_patcriteriaactiveclin();
    
        TYPE t_rec_translation IS RECORD(
            desc_translation pk_translation.t_desc_translation);
        TYPE t_tbl_translation IS TABLE OF t_rec_translation INDEX BY translation.code_translation%TYPE;
    
        translation_cache t_tbl_translation;
    
        -- Função que faz cache das chamadas à pk_translation.get_translation
        FUNCTION get_translation(code_translation translation.code_translation%TYPE)
            RETURN pk_translation.t_desc_translation IS
        
        BEGIN
            IF (NOT translation_cache.exists(code_translation))
            THEN
                translation_cache(code_translation).desc_translation := pk_translation.get_translation(i_lang,
                                                                                                       code_translation);
            END IF;
            RETURN translation_cache(code_translation).desc_translation;
        END;
    
        -- Função que faz cache das chamadas à pk_translation.get_translation_dtchk
        FUNCTION get_translation_dtchk(code_translation translation.code_translation%TYPE)
            RETURN pk_translation.t_desc_translation IS
        
        BEGIN
            IF (NOT translation_cache.exists(code_translation))
            THEN
                translation_cache(code_translation).desc_translation := pk_translation.get_translation_dtchk(i_lang,
                                                                                                             code_translation);
            END IF;
            RETURN translation_cache(code_translation).desc_translation;
        END;
    
    BEGIN
        l_sysdate_char  := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_prof_cat      := pk_edis_list.get_prof_cat(i_prof);
        l_show_inp_epis := pk_sysconfig.get_config('INP_EPIS_IN_ANCILLARY_EDIS', i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
        l_show_only_epis_resp     := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                             i_prof    => i_prof);
    
        --
        g_error     := 'GET NO TR CLR ID';
        l_soft_edis := g_soft_edis;
        --
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
    
        pk_context_api.set_parameter('g_inst_type_h', g_inst_type_h);
        pk_context_api.set_parameter('g_soft_edis', g_soft_edis);
        pk_context_api.set_parameter('g_epis_active', g_epis_active);
        pk_context_api.set_parameter('g_soft_triage', g_soft_triage);
        pk_context_api.set_parameter('g_soft_ubu', g_soft_ubu);
        pk_context_api.set_parameter('g_soft_inp', g_soft_inp);
        pk_context_api.set_parameter('l_prof_cat', l_prof_cat);
        pk_context_api.set_parameter('l_show_inp_epis', l_show_inp_epis);
    
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
    
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
        --
        l_query := 'SELECT ' || nvl(i_hint, 'NULL position, ') || 't.* ' || --
                   ' FROM v_src_edis_active_clin t ' || i_from || --
                   ' WHERE rownum <= :limit + 1 ' || i_where || ' ' || ' ORDER BY rank_acuity, dt_begin_tstz';
        --
        g_error := 'OPEN DATASET';
        OPEN dataset FOR l_query
            USING l_limit;
        --
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
        --
    
        g_error := 'COUNT RESULTS';
        IF (l_dataset.count > l_limit)
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0)
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF (l_dataset.count < l_limit)
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        --
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        WHILE (l_row <= result.count)
        LOOP
        
            out_obj := t_rec_patcriteriaactiveclin(acuity                  => NULL,
                                                   color_text              => NULL,
                                                   rank_acuity             => NULL,
                                                   num_clin_record         => NULL,
                                                   id_episode              => NULL,
                                                   id_patient              => NULL,
                                                   name_pat                => NULL,
                                                   name_pat_sort           => NULL,
                                                   pat_ndo                 => NULL,
                                                   pat_nd_icon             => NULL,
                                                   gender                  => NULL,
                                                   pat_age                 => NULL,
                                                   pat_age_for_order_by    => NULL,
                                                   photo                   => NULL,
                                                   care_stage              => NULL,
                                                   prof_team               => NULL,
                                                   cons_type               => NULL,
                                                   name_prof               => NULL,
                                                   name_nurse              => NULL,
                                                   name_prof_tooltip       => NULL,
                                                   name_nurse_tooltip      => NULL,
                                                   prof_team_tooltip       => NULL,
                                                   dt_server               => NULL,
                                                   dt_begin                => NULL,
                                                   dt_first_obs            => NULL,
                                                   date_send               => NULL,
                                                   date_send_sort          => NULL,
                                                   dt_efectiv              => NULL,
                                                   flg_temp                => NULL,
                                                   desc_temp               => NULL,
                                                   img_transp              => NULL,
                                                   desc_room               => NULL,
                                                   desc_drug_presc         => NULL,
                                                   desc_interv_presc       => NULL,
                                                   desc_monitorization     => NULL,
                                                   desc_movement           => NULL,
                                                   desc_analysis_req       => NULL,
                                                   desc_exam_req           => NULL,
                                                   desc_harvest            => NULL,
                                                   desc_drug_transp        => NULL,
                                                   desc_epis_anamnesis     => NULL,
                                                   desc_spec_prof          => NULL,
                                                   desc_spec_nurse         => NULL,
                                                   desc_disch_pend_time    => NULL,
                                                   flg_cancel              => NULL,
                                                   fast_track_icon         => NULL,
                                                   fast_track_color        => NULL,
                                                   fast_track_status       => NULL,
                                                   fast_track_desc         => NULL,
                                                   desc_supplies           => NULL,
                                                   esi_level               => NULL,
                                                   resp_icons              => NULL,
                                                   prof_follow_add         => NULL,
                                                   prof_follow_remove      => NULL,
                                                   desc_oth_exam_req       => NULL,
                                                   desc_img_exam_req       => NULL,
                                                   desc_opinion            => NULL,
                                                   desc_opinion_popup      => NULL,
                                                   desc_monit_interv_presc => NULL,
                                                   desc_hemo_req           => NULL);
        
            out_obj.acuity          := l_dataset(l_row).acuity;
            out_obj.color_text      := l_dataset(l_row).color_text;
            out_obj.rank_acuity     := l_dataset(l_row).rank_acuity;
            out_obj.num_clin_record := l_dataset(l_row).num_clin_record;
            out_obj.id_episode      := l_dataset(l_row).id_episode;
            out_obj.id_patient      := l_dataset(l_row).id_patient;
            out_obj.name_pat        := l_dataset(l_row).name_pat;
            out_obj.name_pat_sort   := l_dataset(l_row).name_pat_sort;
            out_obj.pat_ndo         := l_dataset(l_row).pat_ndo;
            out_obj.pat_nd_icon     := l_dataset(l_row).pat_nd_icon;
        
            -- cached
            out_obj.gender := pk_patient.get_gender(i_lang, l_dataset(l_row).gender);
        
            out_obj.pat_age := pk_patient.get_pat_age(i_lang,
                                                      l_dataset         (l_row).dt_birth,
                                                      l_dataset         (l_row).dt_deceased,
                                                      l_dataset         (l_row).age,
                                                      i_prof.institution,
                                                      i_prof.software);
        
            out_obj.pat_age_for_order_by := pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                                       i_prof    => i_prof,
                                                                                       i_type    => pk_edis_proc.g_sort_type_age,
                                                                                       i_episode => l_dataset(l_row).id_episode);
        
            out_obj.photo := pk_patphoto.get_pat_photo(i_lang,
                                                       i_prof,
                                                       l_dataset(l_row).id_patient,
                                                       l_dataset(l_row).id_episode,
                                                       NULL);
        
            -- José Brito 16/10/2009 ALERT-39320 Support for multiple hand-off
            -- RESPONSIBLE PHYSICIAN(S)
            -- Get name of the responsible PHYSICIAN to display in the RESULTS GRID
            out_obj.name_prof := pk_hand_off_core.get_responsibles_str(i_lang,
                                                                       i_prof,
                                                                       pk_alert_constant.g_cat_type_doc,
                                                                       l_dataset                       (l_row).id_episode,
                                                                       l_dataset                       (l_row).id_professional,
                                                                       l_hand_off_type,
                                                                       'G',
                                                                       l_show_only_epis_resp);
        
            -- Get name of the responsible physician to display in the grid TOOLTIPS
            CASE l_hand_off_type
                WHEN pk_hand_off.g_handoff_normal THEN
                    out_obj.name_prof_tooltip := out_obj.name_prof;
                WHEN pk_hand_off.g_handoff_multiple THEN
                    out_obj.name_prof_tooltip := pk_hand_off_core.get_responsibles_str(i_lang,
                                                                                       i_prof,
                                                                                       pk_alert_constant.g_cat_type_doc,
                                                                                       l_dataset                       (l_row).id_episode,
                                                                                       l_dataset                       (l_row).id_professional,
                                                                                       l_hand_off_type,
                                                                                       'T');
                ELSE
                    out_obj.name_prof_tooltip := NULL;
            END CASE;
        
            -- RESPONSIBLE NURSE
            IF l_dataset(l_row).id_first_nurse_resp IS NOT NULL
            THEN
                -- Get name of the responsible NURSE to display in the RESULTS GRID
                out_obj.name_nurse := pk_prof_utils.get_nickname(i_lang, l_dataset(l_row).id_first_nurse_resp);
            
                -- Get name of the responsible NURSE to display in the grid TOOLTIPS
                CASE l_hand_off_type
                    WHEN pk_hand_off.g_handoff_normal THEN
                        out_obj.name_nurse_tooltip := out_obj.name_nurse;
                    WHEN pk_hand_off.g_handoff_multiple THEN
                        out_obj.name_nurse_tooltip := pk_hand_off_core.get_responsibles_str(i_lang,
                                                                                            i_prof,
                                                                                            pk_alert_constant.g_cat_type_nurse,
                                                                                            l_dataset                         (l_row).id_episode,
                                                                                            l_dataset                         (l_row).id_first_nurse_resp,
                                                                                            l_hand_off_type,
                                                                                            'T');
                    ELSE
                        out_obj.name_nurse_tooltip := NULL;
                END CASE;
                --
            ELSE
                out_obj.name_nurse         := NULL;
                out_obj.name_nurse_tooltip := NULL;
            END IF;
        
            -- RESPONSIBLE TEAM / RESIDENT PHYSICIAN(S)
            IF l_show_resident_physician = pk_alert_constant.g_yes
            THEN
                out_obj.prof_team := pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                i_prof,
                                                                                l_dataset(l_row).id_episode,
                                                                                l_hand_off_type,
                                                                                pk_hand_off_core.g_resident,
                                                                                'G');
            
            ELSIF l_dataset(l_row).id_professional IS NOT NULL
                   OR l_dataset(l_row).id_first_nurse_resp IS NOT NULL
            THEN
                -- Display TEAM name in grids
                out_obj.prof_team := pk_prof_teams.get_prof_current_team(i_lang,
                                                                         i_prof,
                                                                         l_dataset(l_row).id_department,
                                                                         l_dataset(l_row).id_software,
                                                                         l_dataset(l_row).id_professional,
                                                                         l_dataset(l_row).id_first_nurse_resp);
            ELSE
                out_obj.prof_team         := NULL;
                out_obj.prof_team_tooltip := NULL;
            END IF;
        
            -- Display TEAM name in TOOLTIPS
            IF out_obj.prof_team IS NOT NULL
               OR l_show_resident_physician = pk_alert_constant.g_yes
            THEN
                out_obj.prof_team_tooltip := pk_hand_off_core.get_team_str(i_lang,
                                                                           i_prof,
                                                                           l_dataset        (l_row).id_department,
                                                                           l_dataset        (l_row).id_software,
                                                                           l_dataset        (l_row).id_professional,
                                                                           l_dataset        (l_row).id_first_nurse_resp,
                                                                           l_hand_off_type,
                                                                           out_obj.prof_team);
            ELSE
                out_obj.prof_team_tooltip := NULL;
            END IF;
        
            -- END: ALERT-39320 Support for multiple hand-off
        
            out_obj.dt_server      := l_sysdate_char;
            out_obj.dt_begin       := pk_date_utils.to_char_insttimezone(i_prof,
                                                                         l_dataset(l_row).dt_begin_tstz,
                                                                         g_date_mask);
            out_obj.dt_first_obs   := l_dataset(l_row).dt_first_obs_tstz;
            out_obj.date_send      := pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_id_episode => l_dataset(l_row).id_episode); -- Length of stay
            out_obj.date_send_sort := pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                                 i_prof    => i_prof,
                                                                                 i_type    => pk_edis_proc.g_sort_type_los,
                                                                                 i_episode => l_dataset(l_row).id_episode);
            out_obj.dt_efectiv     := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       l_dataset(l_row).dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software);
            out_obj.flg_temp       := 'N';
            out_obj.desc_temp      := NULL;
            -- cacheable
            out_obj.img_transp := lpad(to_char(pk_sysdomain.get_rank(i_lang,
                                                                     'EPIS_INFO.FLG_STATUS',
                                                                     l_dataset(l_row).flg_status_ei)),
                                       6,
                                       '0') ||
                                  pk_sysdomain.get_img(i_lang, 'EPIS_INFO.FLG_STATUS', l_dataset(l_row).flg_status_ei);
        
            IF (NOT l_dataset(l_row).drug_presc IS NULL)
            THEN
                out_obj.desc_drug_presc := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                  i_prof,
                                                                                  l_dataset(l_row).drug_presc);
            ELSE
                out_obj.desc_drug_presc := NULL;
            END IF;
        
            IF (l_dataset(l_row).intervention IS NOT NULL OR l_dataset(l_row).nurse_activity IS NOT NULL)
            THEN
                out_obj.desc_interv_presc := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                    i_prof,
                                                                                    pk_grid.get_prioritary_task(i_lang,
                                                                                                                i_prof,
                                                                                                                l_dataset         (l_row).intervention,
                                                                                                                l_dataset         (l_row).nurse_activity,
                                                                                                                g_domain_nurse_act,
                                                                                                                l_prof_cat));
            ELSE
                out_obj.desc_interv_presc := NULL;
            END IF;
            IF (NOT l_dataset(l_row).monitorization IS NULL)
            THEN
                out_obj.desc_monitorization := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                      i_prof,
                                                                                      l_dataset(l_row).monitorization);
            ELSE
                out_obj.desc_monitorization := NULL;
            END IF;
            IF (NOT l_dataset(l_row).movement IS NULL)
            THEN
                out_obj.desc_movement := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                i_prof,
                                                                                l_dataset(l_row).movement);
            ELSE
                out_obj.desc_movement := NULL;
            END IF;
            IF (NOT l_dataset(l_row).id_grid_task IS NULL)
            THEN
                IF l_prof_cat = pk_alert_constant.g_flg_nurse
                THEN
                    out_obj.desc_analysis_req := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                        i_prof,
                                                                                        l_dataset(l_row).analysis_n);
                ELSE
                    out_obj.desc_analysis_req := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                        i_prof,
                                                                                        l_dataset(l_row).analysis_d);
                END IF;
            
                out_obj.desc_harvest := pk_grid.visit_grid_task_str(i_lang,
                                                                    i_prof,
                                                                    l_dataset(l_row).id_visit,
                                                                    g_task_harvest,
                                                                    l_prof_cat);
            ELSE
                out_obj.desc_analysis_req := NULL;
                out_obj.desc_exam_req     := NULL;
                out_obj.desc_harvest      := NULL;
            END IF;
        
            out_obj.desc_hemo_req := l_dataset(l_row).hemo_req;
        
            IF (NOT l_dataset(l_row).oth_exam_d IS NULL OR NOT l_dataset(l_row).oth_exam_n IS NULL)
            THEN
                IF l_prof_cat = pk_alert_constant.g_flg_nurse
                THEN
                    out_obj.desc_oth_exam_req := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                        i_prof,
                                                                                        l_dataset(l_row).oth_exam_n);
                ELSE
                    out_obj.desc_oth_exam_req := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                        i_prof,
                                                                                        l_dataset(l_row).oth_exam_d);
                END IF;
            ELSE
                out_obj.desc_oth_exam_req := NULL;
            END IF;
        
            IF (NOT l_dataset(l_row).img_exam_d IS NULL OR NOT l_dataset(l_row).img_exam_n IS NULL)
            THEN
                IF l_prof_cat = pk_alert_constant.g_flg_nurse
                THEN
                    out_obj.desc_img_exam_req := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                        i_prof,
                                                                                        l_dataset(l_row).img_exam_n);
                ELSE
                    out_obj.desc_img_exam_req := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                        i_prof,
                                                                                        l_dataset(l_row).img_exam_d);
                END IF;
            ELSE
                out_obj.desc_img_exam_req := NULL;
            END IF;
        
            IF (NOT l_dataset(l_row).drug_transp IS NULL)
            THEN
                out_obj.desc_drug_transp := pk_grid.convert_grid_task_str(i_lang, i_prof, l_dataset(l_row).drug_transp);
            ELSE
                out_obj.desc_drug_transp := NULL;
            END IF;
        
            out_obj.desc_epis_anamnesis := pk_edis_grid.get_complaint_grid(i_lang,
                                                                           i_prof.institution,
                                                                           i_prof.software,
                                                                           l_dataset(l_row).id_episode);
        
            IF (NOT l_dataset(l_row).discharge_pend IS NULL)
            THEN
                out_obj.desc_disch_pend_time := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                       i_prof,
                                                                                       l_dataset(l_row).discharge_pend);
            ELSE
                out_obj.desc_disch_pend_time := NULL;
            END IF;
        
            out_obj.flg_cancel := pk_visit.check_flg_cancel(i_lang, i_prof, l_dataset(l_row).id_episode);
        
            CASE l_dataset(l_row).has_transfer
                WHEN 0 THEN
                    l_ft_type := pk_alert_constant.g_icon_ft;
                ELSE
                    l_ft_type := pk_alert_constant.g_icon_ft_transfer;
            END CASE;
        
            out_obj.fast_track_icon := pk_fast_track.get_fast_track_icon(i_lang,
                                                                         i_prof,
                                                                         l_dataset(l_row).id_episode,
                                                                         l_dataset(l_row).id_fast_track,
                                                                         l_dataset(l_row).id_triage_color,
                                                                         l_ft_type,
                                                                         l_dataset(l_row).has_transfer);
        
            out_obj.fast_track_color  := CASE l_dataset(l_row).acuity
                                             WHEN g_ft_color THEN
                                              g_ft_triage_white
                                             ELSE
                                              g_ft_color
                                         END;
            out_obj.fast_track_status := g_ft_status;
        
            IF (NOT l_dataset(l_row).id_fast_track IS NULL)
            THEN
                out_obj.fast_track_desc := pk_fast_track.get_fast_track_desc(i_lang,
                                                                             i_prof,
                                                                             l_dataset(l_row).id_fast_track,
                                                                             g_desc_grid);
            ELSE
                out_obj.fast_track_desc := NULL;
            END IF;
        
            IF l_dataset(l_row).id_triage_color IS NOT NULL
            THEN
                out_obj.esi_level := pk_edis_triage.get_epis_esi_level(i_lang,
                                                                       i_prof,
                                                                       l_dataset(l_row).id_episode,
                                                                       l_dataset(l_row).id_triage_color);
            ELSE
                out_obj.esi_level := NULL;
            END IF;
        
            -- COLUNAS COM CACHE
            /*-- cacheable
            IF (NOT l_dataset(l_row).id_clinical_service IS NULL)
            THEN
                out_obj.cons_type := pk_translation.get_translation(i_lang,
                                                                    'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                    l_dataset(l_row).id_clinical_service);
            ELSE
                out_obj.cons_type := NULL;
            END IF;*/
            IF (NOT l_dataset(l_row).id_clinical_service IS NULL)
            THEN
                out_obj.cons_type := get_translation('CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || l_dataset(l_row).id_clinical_service);
            ELSE
                out_obj.cons_type := NULL;
            END IF;
            -- cacheable
            IF (NOT l_dataset(l_row).prof_spec IS NULL)
            THEN
                out_obj.desc_spec_prof := get_translation('SPECIALITY.CODE_SPECIALITY.' || l_dataset(l_row).prof_spec);
            ELSE
                out_obj.desc_spec_prof := NULL;
            END IF;
            -- cacheable
            IF (NOT l_dataset(l_row).nurse_spec IS NULL)
            THEN
                out_obj.desc_spec_nurse := get_translation('SPECIALITY.CODE_SPECIALITY.' || l_dataset(l_row).nurse_spec);
            ELSE
                out_obj.desc_spec_nurse := NULL;
            END IF;
            -- cacheable
            BEGIN
                SELECT r.desc_room_abbreviation, r.desc_room
                  INTO out_obj.desc_room, l_room_desc
                  FROM room r
                 WHERE r.id_room = l_dataset(l_row).id_room;
            EXCEPTION
                WHEN no_data_found THEN
                    out_obj.desc_room := NULL;
                    l_room_desc       := NULL;
            END;
        
            IF out_obj.desc_room IS NULL
            THEN
                out_obj.desc_room := coalesce(out_obj.desc_room,
                                              get_translation_dtchk('ROOM.CODE_ABBREVIATION.' || l_dataset(l_row).id_room),
                                              l_room_desc,
                                              get_translation_dtchk('ROOM.CODE_ROOM.' || l_dataset(l_row).id_room));
            END IF;
        
            out_obj.care_stage := pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                                 i_prof,
                                                                                 l_dataset(l_row).id_episode,
                                                                                 l_sysdate_char);
        
            l_supplies            := pk_supplies_api_db.get_epis_max_supply_delay(i_lang,
                                                                                  i_prof,
                                                                                  l_dataset(l_row).id_patient);
            out_obj.desc_supplies := l_supplies;
        
            --Alexandre Santos 13-10-2010 ALERT-726 Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same.
            out_obj.resp_icons := pk_hand_off_api.get_resp_icons(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_episode      => l_dataset(l_row).id_episode,
                                                                 i_handoff_type => l_hand_off_type);
        
            BEGIN
                SELECT decode(pk_prof_follow.get_follow_episode_by_me(i_prof, l_dataset(l_row).id_episode, -1),
                              pk_alert_constant.g_no,
                              decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                      i_prof,
                                                                                                      l_dataset(l_row).id_episode,
                                                                                                      l_prof_cat,
                                                                                                      l_hand_off_type,
                                                                                                      pk_alert_constant.g_yes),
                                                                  i_prof.id),
                                     -1,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no)
                  INTO out_obj.prof_follow_add
                  FROM dual;
            
            END;
        
            out_obj.prof_follow_remove := pk_prof_follow.get_follow_episode_by_me(i_prof,
                                                                                  l_dataset(l_row).id_episode,
                                                                                  -1);
        
            /************** <DESC_OPINION> *******************/
        
            BEGIN
                SELECT g.opinion_state
                  INTO l_opinion_state
                  FROM grid_task g
                 WHERE g.id_episode = l_dataset(l_row).id_episode;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_opinion_state := NULL;
                
            END;
        
            IF l_opinion_state IS NOT NULL
            THEN
                out_obj.desc_opinion := pk_grid.convert_grid_task_dates_to_str(i_lang => i_lang,
                                                                               i_prof => i_prof,
                                                                               i_str  => l_opinion_state);
            
                out_obj.desc_opinion_popup := pk_opinion.get_epis_last_opinion_popup(i_lang,
                                                                                     i_prof,
                                                                                     l_dataset(l_row).id_episode);
            END IF;
        
            /************** </DESC_OPINION> *******************/
        
            /************** <DESC_MONIT_INTERV_PRESC> **************/
        
            out_obj.desc_monit_interv_presc := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                      i_prof,
                                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                                  i_prof,
                                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                                              i_prof,
                                                                                                                                              l_dataset         (l_row).intervention,
                                                                                                                                              l_dataset         (l_row).nurse_activity,
                                                                                                                                              g_domain_nurse_act,
                                                                                                                                              l_prof_cat),
                                                                                                                  
                                                                                                                  l_dataset(l_row).monitorization,
                                                                                                                  NULL,
                                                                                                                  l_prof_cat));
            /************** </DESC_MONIT_INTERV_PRESC> **************/
        
            RESULT(l_row) := out_obj;
            --
        
            l_row := l_row + 1;
        END LOOP;
        RETURN(RESULT);
        --RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN RESULT;
    END;

    --
    /**********************************************************************************************
    * Contagem de pacientes por sala e por sexo
    *
    * @param i_prof                   professional, software and institution ids
    * @param i_gender                 gender
    * @param i_room                   room id   
    *
    * @return                         value
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_patient_count
    (
        i_prof   IN profissional,
        i_gender IN patient.gender%TYPE,
        i_room   IN room.id_room%TYPE
    ) RETURN NUMBER IS
        l_cont_pat NUMBER(5) := 0;
    BEGIN
        g_error := 'GET COUNT';
        SELECT COUNT(DISTINCT id_episode)
          INTO l_cont_pat
          FROM v_episode_act
          JOIN patient
         USING (id_patient)
         WHERE id_room = i_room
           AND id_software = i_prof.software
           AND id_institution = i_prof.institution
           AND nvl(gender, 'null') = nvl(i_gender, 'null');
    
        RETURN l_cont_pat;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;
    --
    /**********************************************************************************************
    * Contagem dos profissionais por sala
    *
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id   
    * @param i_type_prof              Types of professionals    
    *
    * @return                         value
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_professional_count
    (
        i_prof      IN profissional,
        i_room      IN room.id_room%TYPE,
        i_type_prof IN VARCHAR2
    ) RETURN NUMBER IS
        l_cont_prof PLS_INTEGER;
    BEGIN
        g_error := 'COUNT PROFS';
        SELECT COUNT(pr.id_professional)
          INTO l_cont_prof
          FROM prof_room pr, professional p, prof_cat pc, category cat
         WHERE pr.id_room = i_room
           AND pr.id_professional = p.id_professional
           AND EXISTS (SELECT 0
                  FROM prof_institution pi
                 WHERE pi.id_professional = p.id_professional
                   AND pi.flg_state = g_prof_active
                   AND pi.id_institution = i_prof.institution)
           AND EXISTS
         (SELECT 0
                  FROM prof_in_out pio
                 WHERE pio.id_professional = i_prof.id
                   AND pio.id_prof_in_out = (SELECT MAX(id_prof_in_out)
                                               FROM prof_in_out pio
                                              WHERE pio.id_professional = i_prof.id
                                                AND pio.id_institution = i_prof.institution)
                   AND pio.dt_out_tstz IS NULL)
           AND p.id_professional = pc.id_professional
           AND pc.id_institution = i_prof.institution
           AND pc.id_category = cat.id_category
           AND cat.flg_type = i_type_prof;
        RETURN l_cont_prof;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;
    --
    /**********************************************************************************************
    *  Obter a descrição da categoria do profissional
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_prof                professional id   
    * @param o_cat                    category description  
    * @param o_flg_type               type of category
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/07
    **********************************************************************************************/
    FUNCTION get_category_prof
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_prof  IN professional.id_professional%TYPE,
        o_cat      OUT VARCHAR2,
        o_flg_type OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_cat IS
            SELECT cat.flg_type, pk_translation.get_translation(i_lang, cat.code_category) desc_category
              FROM prof_cat prc, category cat
             WHERE prc.id_professional = nvl(i_id_prof, i_prof.id)
               AND prc.id_institution = i_prof.institution
               AND cat.id_category = prc.id_category
               AND flg_available = g_category_avail
               AND flg_prof = g_cat_prof;
    BEGIN
        g_error := 'GET CURSOR C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO o_flg_type, o_cat;
        CLOSE c_cat;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_CATEGORY_PROF',
                                              o_error);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Registar para um dado episódio o detalhe do transporte de chegada
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id   
    * @param i_dt_transportation      Data do transporte   
    * @param i_id_transp_entity       Transporte entidade   
    * @param i_flg_time               E - início do episódio, S - alta administrativa, T - transporte s/ episódio   
    * @param i_notes                  notes
    * @param i_origin                 origin ID
    * @param i_external_cause         external cause ID
    * @param i_companion              accompanying person
    * @param i_dt_creation              record creation date
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luis Gaspar
    * @version                        1.0 
    * @since                         2007/02/21
    *
    * @alter                         José Brito
    * @version                        1.1 
    * @since                         2009/05/29
    *
    **********************************************************************************************/
    FUNCTION create_transportation_internal
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        i_origin                IN origin.id_origin%TYPE,
        i_external_cause        IN external_cause.id_external_cause%TYPE,
        i_companion             IN epis_info.companion%TYPE,
        i_dt_creation           IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_transportation     OUT transportation.id_transportation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_creation TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        l_dt_creation := nvl(i_dt_creation, current_timestamp);
    
        o_id_transportation := seq_transportation.nextval;
    
        g_error := ' INSERT INTO TRANSPORTATION';
        INSERT INTO transportation
            (id_transportation,
             dt_transportation_tstz,
             id_episode,
             id_professional,
             id_transp_entity,
             flg_time,
             notes,
             id_origin,
             id_external_cause,
             companion,
             dt_creation)
        VALUES
            (o_id_transportation,
             nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_transportation_str, NULL), l_dt_creation),
             i_id_epis,
             i_prof.id,
             nvl(i_id_transp_entity, -1),
             i_flg_time,
             i_notes,
             -- José Brito 29/05/2009 ALERT-30519 CCHIT: add history to "Arrived by"
             i_origin,
             i_external_cause,
             i_companion,
             l_dt_creation);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'CREATE_TRANSPORTATION_INTERNAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Registar para um dado episódio o detalhe do transporte de chegada
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id   
    * @param i_dt_transportation      Data do transporte   
    * @param i_id_transp_entity       Transporte entidade   
    * @param i_flg_time               E - início do episódio, S - alta administrativa, T - transporte s/ episódio   
    * @param i_notes                  notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/06/20
    **********************************************************************************************/
    FUNCTION create_transportation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_transportation_new transportation.id_transportation%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL TO create_transportation_internal';
        IF NOT create_transportation_internal(i_lang,
                                              i_prof,
                                              i_id_epis,
                                              i_dt_transportation_str,
                                              i_id_transp_entity,
                                              i_flg_time,
                                              i_notes,
                                              -- José Brito 29/05/2009 ALERT-30519 CCHIT: add history to "Arrived by"
                                              NULL,
                                              NULL,
                                              NULL,
                                              g_sysdate_tstz,
                                              l_id_transportation_new,
                                              o_error)
        THEN
            RAISE e_call_exception;
        END IF;
        --
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE e_call_exception;
        END IF;
        --
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'CREATE_TRANSPORTATION',
                                              o_error);
            pk_utils.undo_changes;
        
    END;
    --
    /**********************************************************************************************
    * Listar o detalhe do último transporte de chegada registado para um episódio clinico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id   
    * @param o_transp                 cursor with all information of last transport
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/06/20
    **********************************************************************************************/
    FUNCTION get_transportation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_transp  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_TRANSP';
        OPEN o_transp FOR
            SELECT tr.id_transportation,
                   tr.dt_transportation_tstz,
                   tr.id_professional,
                   tr.id_transp_entity,
                   pk_translation.get_translation(i_lang, te.code_transp_entity) transp_entity,
                   tr.flg_time,
                   tr.notes
              FROM transportation tr, transp_entity te
             WHERE tr.id_episode = i_id_epis
               AND te.id_transp_entity = tr.id_transp_entity
               AND tr.dt_transportation_tstz = (SELECT MAX(tt.dt_transportation_tstz)
                                                  FROM transportation tt
                                                 WHERE tt.id_episode = i_id_epis);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_transp);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_TRANSPORTATION',
                                              o_error);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Listar as cores / detalhe, disponiveis para o cabeçalho conforme o tipo de triagem : Manchester ou Triage Nurse
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_head_col               cursor with all cabeçalho das cores, bem como toda a informação a elas associadas
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/06/22
    **********************************************************************************************/
    FUNCTION get_chart_header
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_room     IN room.id_room%TYPE,
        o_head_col OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pcat                 category.flg_type%TYPE;
        l_tab_inst_triag_types table_number;
        l_tab_triage_color     table_number;
        l_tab_color_groups     table_number;
        l_minutes_desc         VARCHAR2(200);
        l_hand_off_type        sys_config.value%TYPE;
        l_aux_grid             VARCHAR2(1 CHAR);
        l_config_grid_aux CONSTANT sys_config.id_sys_config%TYPE := 'SHOW_ALL_PATIENTS_AUX_GRID';
        l_show_all sys_config.value%TYPE;
    BEGIN
        g_error        := 'GET INITIAL DATA';
        l_pcat         := pk_edis_list.get_prof_cat(i_prof);
        l_minutes_desc := pk_translation.get_translation(i_lang, 'TRIAGE_UNITS.CODE_TRIAGE_UNITS.1'); -- "Min"
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error                := 'GET INST TRIAGE_TYPES';
        l_tab_inst_triag_types := pk_edis_triage.tf_get_inst_triag_types(i_prof.institution);
    
        -- José Brito 16/09/2009 ALERT-42214 
        -- Get all triage colors used in the institution
        g_error := 'GET TRIAGE COLORS';
        SELECT tco1.id_triage_color
          BULK COLLECT
          INTO l_tab_triage_color
          FROM triage_color tco1,
               (SELECT tab.column_value id_triage_type
                  FROM TABLE(l_tab_inst_triag_types) tab) t
         WHERE tco1.flg_show = g_tr_color_flg_show
           AND tco1.id_triage_type = t.id_triage_type;
    
        -- Get color groups
        g_error := 'GET TRIAGE COLOR GROUPS';
        SELECT tco1.id_triage_color_group
          BULK COLLECT
          INTO l_tab_color_groups
          FROM triage_color tco1,
               (SELECT tab.column_value id_triage_color
                  FROM TABLE(l_tab_triage_color) tab) t
         WHERE tco1.id_triage_color = t.id_triage_color;
    
        -- Clear repeated elements
        l_tab_color_groups := l_tab_color_groups MULTISET UNION DISTINCT l_tab_color_groups;
    
        g_error    := 'CHECK ANCILLARY CONFIGURATION';
        l_show_all := pk_sysconfig.get_config(l_config_grid_aux, i_prof);
    
        IF l_pcat = 'O'
           AND l_show_all = pk_alert_constant.g_no
        THEN
            l_aux_grid := pk_alert_constant.g_yes;
        ELSE
            l_aux_grid := pk_alert_constant.g_no;
        END IF;
    
        -- José Brito 16/09/2009 ALERT-42214
        -- Query completely rewritten to support color groups
        g_error := 'GET CURSOR O_HEAD_COL';
        OPEN o_head_col FOR
            SELECT tcg.id_triage_color_group,
                   tcg.color,
                   tcg.color_text,
                   tcg.flg_ref_line,
                   tcg.length_color,
                   l_minutes_desc units,
                   -- Get the maximum SCALE TIME of all triage types used in the institution
                   (SELECT MAX(tci.scale_time)
                      FROM triage_color_time_inst tci, triage_color tco
                     WHERE tci.id_triage_color = tco.id_triage_color
                       AND tco.id_triage_color_group = tcg.id_triage_color_group
                       AND tco.id_triage_type IN (SELECT column_value
                                                    FROM TABLE(l_tab_inst_triag_types))
                       AND (tci.id_institution = 0 AND NOT EXISTS
                            (SELECT 0
                               FROM triage_color_time_inst t1
                              WHERE t1.id_triage_color = tco.id_triage_color
                                AND t1.id_institution = i_prof.institution) OR tci.id_institution = i_prof.institution)) scale_time,
                   -- Get the maximum SCALE TIME INTERVAL of all triage types used in the institution
                   (SELECT MAX(tci.scale_time_interv)
                      FROM triage_color_time_inst tci, triage_color tco
                     WHERE tci.id_triage_color = tco.id_triage_color
                       AND tco.id_triage_color_group = tcg.id_triage_color_group
                       AND tco.id_triage_type IN (SELECT column_value
                                                    FROM TABLE(l_tab_inst_triag_types))
                       AND (tci.id_institution = 0 AND NOT EXISTS
                            (SELECT 0
                               FROM triage_color_time_inst t1
                              WHERE t1.id_triage_color = tco.id_triage_color
                                AND t1.id_institution = i_prof.institution) OR tci.id_institution = i_prof.institution)) scale_time_interv,
                   -- Count number of episodes for each color group
                   decode(i_flg_type,
                          'M',
                          (SELECT COUNT(0)
                             FROM v_episode_act e
                            WHERE e.id_triage_color IN (SELECT tco1.id_triage_color
                                                          FROM triage_color tco1
                                                         WHERE tco1.id_triage_color_group = tcg.id_triage_color_group
                                                           AND tco1.id_triage_color IN
                                                               (SELECT *
                                                                  FROM TABLE(l_tab_triage_color)))
                              AND e.id_software = i_prof.software
                              AND e.id_institution = i_prof.institution
                              AND e.flg_ehr = 'N'
                                 --- José Brito 22/10/2009 ALERT-39320 Support for multiple hand-off mechanism
                              AND ((i_prof.id IN
                                  (SELECT column_value
                                       FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                       i_prof,
                                                                                       e.id_episode,
                                                                                       l_pcat,
                                                                                       l_hand_off_type))) AND
                                  l_pcat IN ('D', 'N')) OR (l_pcat = 'M' AND e.id_first_nurse_resp = i_prof.id))),
                          'A',
                          (SELECT COUNT(0)
                             FROM v_episode_act e, institution i
                            WHERE e.id_triage_color IN (SELECT tco1.id_triage_color
                                                          FROM triage_color tco1
                                                         WHERE tco1.id_triage_color_group = tcg.id_triage_color_group
                                                           AND tco1.id_triage_color IN
                                                               (SELECT *
                                                                  FROM TABLE(l_tab_triage_color)))
                                 -- Show EDIS/UBU episodes in ALERT® Triage
                              AND e.id_software = decode(i_prof.software,
                                                         g_soft_triage,
                                                         decode(i.flg_type, g_inst_type_h, g_soft_edis, g_soft_ubu),
                                                         i_prof.software)
                              AND e.id_institution = i.id_institution
                              AND e.id_institution = i_prof.institution
                              AND e.flg_ehr = 'N'
                              AND decode(l_aux_grid,
                                         pk_alert_constant.g_yes,
                                         (SELECT 1
                                            FROM grid_task gt
                                           WHERE gt.id_episode = e.id_episode
                                             AND nvl(gt.movement, gt.harvest) IS NOT NULL),
                                         1) = 1),
                          'R',
                          (SELECT COUNT(0)
                             FROM v_episode_act e
                            WHERE e.id_triage_color IN (SELECT tco1.id_triage_color
                                                          FROM triage_color tco1
                                                         WHERE tco1.id_triage_color_group = tcg.id_triage_color_group
                                                           AND tco1.id_triage_color IN
                                                               (SELECT *
                                                                  FROM TABLE(l_tab_triage_color)))
                              AND e.id_software = i_prof.software
                              AND e.id_institution = i_prof.institution
                              AND e.flg_ehr = 'N'
                              AND e.id_room = i_room
                               OR i_room IS NULL)) epis_count
              FROM triage_color_group tcg,
                   -- Groups of colours used in the institution
                   (SELECT tab.column_value id_triage_color_group
                      FROM TABLE(l_tab_color_groups) tab) t
             WHERE tcg.id_triage_color_group = t.id_triage_color_group
             ORDER BY tcg.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_head_col);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_CHART_HEADER',
                                              o_error);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Contagem de pacientes para cada côr
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               Tipo de listagem: M - My Patients; A - All Patients; R - Por sala
    * @param i_color                  color id
    * @param i_room                   room id
    * @param o_pat                    patient id
    * @param o_color                  color detail
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/06/23
    **********************************************************************************************/
    FUNCTION get_chart_pat_color
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_color    IN triage_color.id_triage_color%TYPE,
        i_room     IN room.id_room%TYPE,
        o_pat      OUT NUMBER,
        o_color    OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_cat     category.flg_type%TYPE;
        l_pat          NUMBER;
        l_color        NUMBER;
        l_prof_profile profile_template.id_profile_template%TYPE;
        l_handoff_type sys_config.value%TYPE;
        --
        CURSOR c_flg_type IS
            SELECT cat.flg_type
              FROM prof_cat prc, category cat
             WHERE prc.id_professional = i_prof.id
               AND prc.id_institution = i_prof.institution
               AND cat.id_category = prc.id_category
               AND flg_available = g_category_avail
               AND flg_prof = g_cat_prof;
    
        CURSOR c_pat_cont_m IS
            SELECT COUNT(epis.id_patient), epis.id_triage_color cor
              FROM v_episode_act epis
             WHERE epis.id_institution = i_prof.institution
               AND pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                    i_prof,
                                                                                    epis.id_episode,
                                                                                    l_prof_cat,
                                                                                    l_handoff_type),
                                                i_prof.id) != -1
               AND epis.id_triage_color = i_color
               AND epis.id_software = i_prof.software
             GROUP BY epis.id_triage_color;
    
        CURSOR c_pat_cont_a(l_prof_profile IN profile_template.id_profile_template%TYPE) IS
            SELECT COUNT(epis.id_patient), epis.id_triage_color cor
              FROM v_episode_act epis, institution i
             WHERE epis.id_institution = i_prof.institution
               AND epis.id_triage_color = i_color
                  --José Brito 10/07/2008 Mostrar episódios do EDIS/UBU no ALERT® Triage
               AND epis.id_software = decode(i_prof.software,
                                             g_soft_triage,
                                             decode(i.flg_type, g_inst_type_h, g_soft_edis, g_soft_ubu),
                                             i_prof.software)
               AND epis.id_institution = i.id_institution
                  --
               AND EXISTS (SELECT 0
                      FROM prof_room pr
                     WHERE pr.id_professional = i_prof.id
                       AND epis.id_room = pr.id_room)
               AND decode(l_prof_profile,
                          g_profile_edis_anciliary,
                          (SELECT COUNT(0)
                             FROM grid_task gt
                            WHERE gt.id_episode = epis.id_episode
                              AND nvl(gt.movement, gt.harvest) IS NOT NULL),
                          1) = 1
             GROUP BY epis.id_triage_color;
    
        CURSOR c_pat_cont_r IS
            SELECT COUNT(epis.id_patient), epis.id_triage_color cor
              FROM v_episode_act epis
             WHERE epis.id_institution = i_prof.institution
               AND epis.id_room = i_room
               AND epis.id_triage_color = i_color
               AND epis.id_software = i_prof.software
             GROUP BY epis.id_triage_color;
    
        CURSOR c_prof_template IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template pt
             WHERE ppt.id_profile_template = pt.id_profile_template
               AND pt.id_software = i_prof.software
               AND ppt.id_professional = i_prof.id
               AND ppt.id_software = i_prof.software
               AND ppt.id_institution = i_prof.institution;
    BEGIN
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        --        
        g_error := 'OPEN c_prof_template';
        OPEN c_prof_template;
        FETCH c_prof_template
            INTO l_prof_profile;
        CLOSE c_prof_template;
        --
        -- Qual a categoria do profissional
        g_error    := 'GET CAT';
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        --
        IF i_flg_type = 'M'
        THEN
            g_error := 'GET CURSOR C_PAT_CONT_M';
            OPEN c_pat_cont_m;
            FETCH c_pat_cont_m
                INTO l_pat, l_color;
            CLOSE c_pat_cont_m;
        
            IF l_pat IS NULL
            THEN
                l_pat := 0;
            END IF;
            o_pat   := l_pat;
            o_color := l_color;
        ELSIF i_flg_type = 'A'
        THEN
            g_error := 'GET CURSOR C_PAT_CONT_A';
            OPEN c_pat_cont_a(l_prof_profile);
            FETCH c_pat_cont_a
                INTO l_pat, l_color;
            CLOSE c_pat_cont_a;
            --
            IF l_pat IS NULL
            THEN
                l_pat := 0;
            END IF;
            o_pat   := l_pat;
            o_color := l_color;
        ELSE
            g_error := 'GET CURSOR C_PAT_CONT_R';
            OPEN c_pat_cont_r;
            FETCH c_pat_cont_r
                INTO l_pat, l_color;
            CLOSE c_pat_cont_r;
            --
            IF l_pat IS NULL
            THEN
                l_pat := 0;
            END IF;
            o_pat   := l_pat;
            o_color := l_color;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_CHART_PAT_COLOR',
                                              o_error);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Listar todos os episódios inactivos e pendentes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_epis_inact             array with inactive episodes
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_flg_show                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_epis_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_inact      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where CLOB;
        l_from  VARCHAR2(32767);
        l_hint  VARCHAR2(32767);
    
        l_ret BOOLEAN;
    
    BEGIN
        --
        o_flg_show := 'N';
        --
        l_where := NULL;
        --
        g_error := 'GET WHERE';
        IF (NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                    i_crit_val => i_crit_val,
                                    i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    o_where    => l_where))
        THEN
            l_where := NULL;
        END IF;
    
        g_error := 'GET FROM';
        IF (NOT pk_search.get_from(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   o_from     => l_from,
                                   o_hint     => l_hint))
        THEN
            l_from := NULL;
        END IF;
        --
        g_error      := 'OPEN CURSOR O_EPIS_INACT';
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        --
        OPEN o_epis_inact FOR
            SELECT *
              FROM TABLE(tf_epis_inactive(i_lang, i_prof, l_where, l_from, l_hint));
    
        IF (g_overlimit = TRUE)
        THEN
            RAISE pk_search.e_overlimit;
        ELSE
            IF (g_no_results = TRUE)
            THEN
                RAISE pk_search.e_noresults;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_epis_inact);
        
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_EPIS_INACTIVE', o_error);
            RETURN TRUE;
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_epis_inact);
        
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_EPIS_INACTIVE', o_error);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_INACTIVE',
                                              o_error);
        
            pk_types.open_my_cursor(o_epis_inact);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END;

    FUNCTION tf_epis_inactive
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN CLOB,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_episinactive IS
        dataset pk_types.cursor_type;
        l_limit sys_config.desc_sys_config%TYPE;
        out_obj t_rec_episinactive := t_rec_episinactive(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
    
        CURSOR l_cur IS
            SELECT *
              FROM (SELECT counter,
                           t.dt_birth,
                           t.name_pat,
                           t.name_pat_sort,
                           t.pat_ndo,
                           t.pat_nd_icon,
                           t.id_patient id_patient,
                           (SELECT location
                              FROM pat_soc_attributes) location,
                           1 position
                      FROM (SELECT *
                              FROM v_src_edis_inp_inactive t) t);
    
        TYPE dataset_tt IS TABLE OF l_cur%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset  dataset_tt;
        l_row      PLS_INTEGER := 1;
        l_prof_cat VARCHAR2(1);
        RESULT     t_coll_episinactive := t_coll_episinactive();
    
        l_query VARCHAR2(32767);
    
    BEGIN
        --
        g_error    := 'GET LIMIT';
        l_limit    := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('id_epis_type',
                                     CASE i_prof.software WHEN 8 THEN CASE l_prof_cat WHEN 'A' THEN 5 ELSE NULL END WHEN 11 THEN CASE
                                     l_prof_cat WHEN 'A' THEN NULL ELSE 5 END ELSE NULL END);
    
        pk_context_api.set_parameter('g_epis_inactive', g_epis_inactive);
        pk_context_api.set_parameter('g_epis_pending', g_epis_pending);
    
        pk_context_api.set_parameter('i_inst_grp_flg_relation', g_inst_grp_flg_rel_adt);
    
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
    
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
        l_query := 'SELECT counter, ' || --
                   ' t.dt_birth, ' || --
                   ' t.name_pat, ' || --
                   ' t.name_pat_sort, ' || --
                   ' t.pat_ndo, ' || --
                   ' t.pat_nd_icon, ' || --
                   ' t.id_patient id_patient, ' || --
                   ' pk_patient.get_pat_location(:i_prof_institution, :g_inst_grp_flg_rel_adt, t.id_patient) location, ' || --
                   ' t.position ' || --
                   ' FROM (SELECT ' || nvl(i_hint, 'NULL position, ') || 't.* ' || --
                   ' FROM v_src_edis_inp_inactive t ' || i_from || --
                   ' WHERE rownum <= :l_limit + 1 ' || --
                   i_where || --
                   ' ) t ' || --
                   ' GROUP BY counter, id_patient, name_pat, name_pat_sort, pat_ndo, pat_nd_icon, dt_birth, position' || --
                   ' ORDER BY position, name_pat_sort ';
    
        g_error := 'OPEN DATASET';
        OPEN dataset FOR l_query
            USING --
        i_prof.institution, --
        g_inst_grp_flg_rel_adt, --
        l_limit;
        --
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
        --
    
        g_error := 'COUNT RESULTS';
        IF (l_dataset.count > l_limit)
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0)
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF (l_dataset.count < l_limit)
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        --
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        WHILE (l_row <= result.count)
        LOOP
            out_obj.num_episode := l_dataset(l_row)
                                   .counter + pk_edis_proc.get_prev_episode(i_lang,
                                                                            l_dataset(l_row).id_patient,
                                                                            i_prof.institution,
                                                                            i_prof.software);
            IF (NOT l_dataset(l_row).dt_birth IS NULL)
            THEN
                out_obj.dt_birth_string := pk_date_utils.dt_chr(i_lang,
                                                                l_dataset(l_row).dt_birth,
                                                                i_prof.institution,
                                                                i_prof.software);
                out_obj.dt_birth        := to_char(l_dataset(l_row).dt_birth, g_date_mask);
            ELSE
                out_obj.dt_birth_string := NULL;
                out_obj.dt_birth        := NULL;
            END IF;
            out_obj.name_pat      := l_dataset(l_row).name_pat;
            out_obj.name_pat_sort := l_dataset(l_row).name_pat_sort;
            out_obj.pat_ndo       := l_dataset(l_row).pat_ndo;
            out_obj.pat_nd_icon   := l_dataset(l_row).pat_nd_icon;
            out_obj.location      := l_dataset(l_row).location;
            out_obj.id_patient    := l_dataset(l_row).id_patient;
        
            RESULT(l_row) := out_obj;
            --
        
            l_row := l_row + 1;
        END LOOP;
        RETURN(RESULT);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN RESULT;
    END;

    --
    /**********************************************************************************************
    * Listar todos os episódios inactivos e pendentes para um determinado paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_epis_inact             cursor with episódios inactivos de um paciente   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/08/10
    * @notes                          Os episódios onde se podem registar notas pós-alta são:os que têm origem no software (I_PROF.SOFTWARE)
                                                                                             ou que têm como EPISODE.ID_EPISODE_ORIGIN 
                                                                                             um episódio originado no software (I_PROF_.SOFTWARE).
                                      Nem todas as categorias de profissionais podem fazer reaberturas. 
                                      Essa validação é feita posteriormente.
                                      Não considerar altas canceladas.
    **********************************************************************************************/
    FUNCTION get_epis_pat_inactive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        o_epis_inact OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat_ext IS
            SELECT VALUE
              FROM pat_ext_sys pes
             WHERE pes.id_patient = i_patient
               AND pes.id_external_sys = pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof)
               AND pes.id_institution = i_prof.institution;
        --
        l_pat         pat_ext_sys.value%TYPE;
        l_aux_sql     VARCHAR2(32767);
        l_exist_er    sys_config.value%TYPE;
        l_flg_pending episode.flg_status%TYPE;
    BEGIN
        g_error    := 'CALL TO PK_SYSCONFIG.GET_CONFIG';
        l_exist_er := pk_sysconfig.get_config('ER_CLIENT_SERVER', i_prof);
    
        /*Administrativo deve obter episódios com estado pendente para ficar coerente com a pesquisa de inactivos*/
        --IF pk_tools.get_prof_cat(i_prof) != g_prof_cat_administrative
        --THEN
        l_flg_pending := g_epis_pending;
        --END IF;
        --
        IF l_exist_er = 'Y'
        THEN
            g_error := 'OPEN C_PAT_EXT';
            OPEN c_pat_ext;
            FETCH c_pat_ext
                INTO l_pat;
            CLOSE c_pat_ext;
            --        
        
            g_error   := 'CONCAT O_EPIS_INACT (1)';
            l_aux_sql := 'SELECT epis.id_episode, ' || --
                         '       epis.id_epis_type, ' || --
                         '       pk_date_utils.date_chr_short_read_tsz(:i_lang, epis.dt_begin_tstz, :i_prof_institution, :i_prof_software) date_target_admin, ' || --
                         '       pk_date_utils.date_char_hour_tsz(:i_lang, epis.dt_begin_tstz, :i_prof_institution, :i_prof_software) hour_target_admin, ' || --
                         '       pk_date_utils.to_char_insttimezone(:i_prof, epis.dt_begin_tstz, :g_date_mask) date_admin, ' || --
                         '       pk_edis_proc.get_epis_inact_diag(:i_lang, epis.id_episode) desc_final_diagnosis, ' || --
                         '       pk_translation.get_translation(:i_lang, ''AB_INSTITUTION.CODE_INSTITUTION.''||epis.id_institution)||chr(10)|| ' || --
                         '       pk_translation.get_translation(:i_lang, et.code_epis_type) desc_encouter_type, ' || --
                         '       pk_date_utils.date_chr_short_read_tsz(:i_lang, ' || --
                         '                                             nvl(disch.dt_med_tstz, disch.dt_admin_tstz), ' || --
                         '                                             :i_prof_institution, ' || --
                         '                                             :i_prof_software) date_target_disch, ' || --
                         '       pk_date_utils.date_char_hour_tsz(:i_lang, ' || --
                         '                                        nvl(disch.dt_med_tstz, disch.dt_admin_tstz), ' || --
                         '                                        :i_prof_institution, ' || --
                         '                                        :i_prof_software) hour_target_disch, ' || --
                         '       pk_date_utils.to_char_insttimezone(:i_prof, nvl(disch.dt_med_tstz, disch.dt_admin_tstz), :g_date_mask) date_disch, ' || --
                         '       pk_translation.get_translation(:i_lang, ''DISCHARGE_DEST.CODE_DISCHARGE_DEST.'' || disch.id_discharge_dest) disposition, ' || --
                         '       (SELECT nvl(nick_name, name) ' || --
                         '          FROM professional ' || --
                         '         WHERE id_professional = disch.id_prof_med) name_prof, ' || --
                         '       decode(pk_episode.get_soft_by_epis_type(epis.id_epis_type, :i_prof_institution), :i_prof_software, decode(epis.id_institution, :i_prof_institution, ''Y'', ''N''), ''N'') flg_reopen, ' || --
                         '       :g_flg_type_cons flg_type, ' || --
                         '       pk_date_utils.to_char_insttimezone(:i_prof, epis.dt_begin_tstz, :g_date_mask) dt_begin ' || --
                         '  FROM episode epis, ' || --
                         '       epis_type et, ' || --
                         '       (SELECT * ' || --
                         '          FROM discharge ' || --
                         '          JOIN disch_reas_dest ' || --
                         '         USING (id_disch_reas_dest) ' || --
                         '         WHERE flg_status = :g_discharge_flg_status_active) disch ' || --
                         ' WHERE epis.flg_status IN (:g_epis_inactive, :g_epis_pending) ' || --
                         '   AND et.id_epis_type = epis.id_epis_type ' || --
                         '   AND epis.id_patient = :i_patient ' || --
                         '   AND disch.id_episode(+) = epis.id_episode ' || --
                         '   AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, :i_prof_institution) = :i_prof_software ' || -- 
                         '   AND epis.flg_ehr = ''N'' ' || --
                         'UNION ALL ' || --
                         'SELECT voe.id_episode, ' || --
                         '       decode(voe.flg_type, ''URG'', 2) id_epis_type, ' || --
                         '       pk_date_utils.date_chr_short_read(:i_lang, voe.dt_begin, :i_prof_institution, :i_prof_software) date_target_admin, ' || --
                         '       pk_date_utils.date_char_hour(:i_lang, voe.dt_begin, :i_prof_institution, :i_prof_software) hour_target_admin, ' || --
                         '       to_char(voe.dt_begin, :g_date_mask) date_admin, ' || --
                         '       pk_edis_proc.get_epis_inact_diag(:i_lang, voe.id_episode) desc_final_diagnosis, ' || --
                         '       voe.flg_type desc_encouter_type, ' || --
                         '       NULL date_target_disch, ' || --
                         '       NULL hour_target_disch, ' || --
                         '       NULL date_disch, ' || --
                         '       NULL disposition, ' || --
                         '       voe.nick_name name_prof, ' || --
                         '       ''N'' flg_reopen, ' || --
                         '       voe.flg_type flg_type, ' || --
                         '       to_char(dt_begin, :g_date_mask) dt_begin ' || --
                         '  FROM v_outp_episodes voe ' || --
                         ' WHERE id_pat_ext = :l_pat ' || --
                         ' ORDER BY dt_begin DESC ';
            --
            g_error := 'OPEN O_EPIS_INACT (1)';
            OPEN o_epis_inact FOR l_aux_sql
                USING --
            i_lang, --
            i_prof.institution, --
            i_prof.software, --
            i_lang, --
            i_prof.institution, --
            i_prof.software, --
            i_prof, --
            g_date_mask, --
            i_lang, --
            i_lang, --
            i_lang, --
            i_lang, --
            i_prof.institution, --
            i_prof.software, --
            i_lang, --
            i_prof.institution, --            
            i_prof.software, --
            
            i_prof, --
            g_date_mask, --           
            i_lang, --
            i_prof.institution, --
            
            i_prof.software, --
            i_prof.institution, --
            g_flg_type_cons, --
            i_prof, --
            g_date_mask, --
            g_discharge_flg_status_active, --
            
            g_epis_inactive, --
            l_flg_pending, --
            i_patient, --
            ---
            i_prof.institution, --
            i_prof.software, --
            ---
            i_lang, --
            i_prof.institution, --
            i_prof.software, --
            i_lang, --
            i_prof.institution, --
            i_prof.software, --
            g_date_mask, --
            i_lang, --
            g_date_mask, --
            l_pat;
        ELSE
            g_error := 'OPEN O_EPIS_INACT (2)';
            OPEN o_epis_inact FOR
                SELECT epis.id_episode,
                       epis.id_epis_type,
                       pk_episode.get_soft_by_epis_type(epis.id_epis_type, i_prof.institution) id_software,
                       pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                             epis.dt_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) date_target_admin,
                       pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) hour_target_admin,
                       pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz, g_date_mask) date_admin,
                       pk_edis_proc.get_epis_inact_diag(i_lang, epis.id_episode) desc_final_diagnosis,
                       pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || epis.id_institution) ||
                       chr(10) || pk_translation.get_translation(i_lang, et.code_epis_type) desc_encouter_type,
                       pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                             nvl(disch.dt_med_tstz, disch.dt_admin_tstz),
                                                             i_prof.institution,
                                                             i_prof.software) date_target_disch,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        nvl(disch.dt_med_tstz, disch.dt_admin_tstz),
                                                        i_prof.institution,
                                                        i_prof.software) hour_target_disch,
                       pk_date_utils.to_char_insttimezone(i_prof,
                                                          nvl(disch.dt_med_tstz, disch.dt_admin_tstz),
                                                          g_date_mask) date_disch,
                       pk_translation.get_translation(i_lang,
                                                      'DISCHARGE_DEST.CODE_DISCHARGE_DEST.' || disch.id_discharge_dest) disposition,
                       (SELECT nvl(nick_name, name)
                          FROM professional
                         WHERE id_professional = disch.id_prof_med) name_prof,
                       check_flg_reopen(i_lang,
                                        i_prof,
                                        epis.id_episode,
                                        pk_episode.get_soft_by_epis_type(et.id_epis_type, i_prof.institution)) flg_reopen,
                       g_flg_type_cons flg_type,
                       pk_date_utils.to_char_insttimezone(i_prof, epis.dt_begin_tstz, g_date_mask) dt_begin
                  FROM episode epis,
                       epis_type et,
                       (SELECT *
                          FROM discharge
                          JOIN disch_reas_dest
                         USING (id_disch_reas_dest)
                         WHERE flg_status = g_discharge_flg_status_active) disch
                 WHERE epis.flg_status IN (g_epis_inactive, l_flg_pending)
                   AND et.id_epis_type = epis.id_epis_type
                   AND disch.id_episode(+) = epis.id_episode
                   AND epis.id_patient = i_patient
                   AND epis.flg_ehr = pk_alert_constant.g_no
                 ORDER BY dt_begin DESC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_inact);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_PAT_INACTIVE',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter todos os diagnósticos finais de um episódio inactivo
    *
    * @param i_lang                 the id language
    * @param i_episode              episode id   
    *
    * @return                       diagnosis description 
    *                        
    * @author                       Emília Taborda
    * @version                      1.0 
    * @since                        2006/12/20
    **********************************************************************************************/
    FUNCTION get_epis_inact_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ediag VARCHAR2(30000);
        c_diags pk_types.cursor_type;
        --
        l_inst institution.id_institution%TYPE;
        l_soft software.id_software%TYPE;
    BEGIN
        g_error := 'GET INST AND SOFT OF EPISODE';
        SELECT epis.id_institution, ei.id_software
          INTO l_inst, l_soft
          FROM episode epis
          JOIN epis_info ei
            ON ei.id_episode = epis.id_episode
         WHERE epis.id_episode = i_episode;
    
        g_error := 'OPEN C_EPIS_DIAG ';
        OPEN c_diags FOR
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => profissional(NULL, l_inst, l_soft),
                                              i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                              i_id_diagnosis        => dg.id_diagnosis,
                                              i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                              i_code                => dg.code_icd,
                                              i_flg_other           => dg.flg_other,
                                              i_flg_std_diag        => ad.flg_icd9,
                                              i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis
              FROM epis_diagnosis ed, diagnosis dg, alert_diagnosis ad
             WHERE ed.id_episode = i_episode
               AND ed.id_diagnosis = dg.id_diagnosis
               AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND ed.flg_status IN (g_epis_diag_confirmed, g_epis_diag_despiste, pk_diagnosis.g_ed_flg_status_p)
               AND ed.flg_type = g_epis_diag_type_definitive
             ORDER BY pk_sysdomain.get_rank(i_lang, 'EPIS_DIAGNOSIS.FLG_STATUS', ed.flg_status);
    
        l_ediag := pk_utils.concatenate_list(c_diags, '; ');
    
        RETURN l_ediag;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;
    --
    /**********************************************************************************************
    * Listar todos os meus episódios INACTIVOS nas últimas 24 horas (Episódios de Urgência e de internamento)
    *
    * @param i_lang                 the id language
    * @param i_prof                 professional, software and institution ids
    * @param i_type_inactive        Tipo de pesquisa de inactivos: MI24 - Meus doentes nas últimas 24 horas
                                                                   I24 -  doentes nas últimas 24 horas   
    * @param i_prof_cat_type        professional category      
    * @param o_epis_inact           cursor with all episode inactiv
    * @param o_error                Error message
    *
    * @return                       TRUE if sucess, FALSE otherwise                            
    *
    * @author                       Emília Taborda
    * @version                      1.0 
    * @since                        2007/01/22
    **********************************************************************************************/
    FUNCTION get_epis_inactive_24
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_inactive IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_epis_inact    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type     epis_type.id_epis_type%TYPE;
        l_hand_off_type sys_config.value%TYPE;
        l_dt_med_24     discharge.dt_med_tstz%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_dt_med_24 := current_timestamp - 1;
        --
        g_error := 'GET EPIS TYPE';
        -- José Brito 15/05/2008 Return EPIS_TYPE through SYS_CONFIG
        l_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        IF l_epis_type IS NULL
        THEN
            l_epis_type := 0;
        END IF;
        -- 
        IF i_type_inactive = g_inactive_m24
        THEN
            -- Meus doentes
            IF i_prof_cat_type = g_prof_cat_doctor
            THEN
                g_error := 'OPEN O_EPIS_INACT 1';
                OPEN o_epis_inact FOR
                    SELECT (SELECT COUNT(epis2.id_episode) counter
                              FROM episode epis2
                             WHERE epis2.flg_ehr = 'N'
                               AND epis2.flg_status IN (g_epis_inactive, g_epis_pending)
                               AND epis2.id_patient = pat.id_patient
                             GROUP BY epis2.id_patient) num_episode,
                           pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof.institution, i_prof.software) dt_birth_string,
                           pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) dt_birth,
                           pat.id_patient,
                           pk_adt.get_patient_name(i_lang, i_prof, pat.id_patient, pk_adt.g_true) name_pat,
                           -- ALERT-102882 Patient name used for sorting
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, pat.id_patient, NULL, NULL) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon,
                           (SELECT location
                              FROM pat_soc_attributes
                             WHERE id_patient = pat.id_patient
                               AND id_institution = i_prof.institution) location
                      FROM patient pat
                     WHERE pat.id_patient IN (SELECT v1.id_patient
                                                FROM (SELECT e.id_patient, ei.id_episode
                                                        FROM discharge d, episode e, epis_info ei
                                                       WHERE d.dt_med_tstz >= l_dt_med_24
                                                         AND d.dt_cancel_tstz IS NULL
                                                         AND d.id_episode = e.id_episode
                                                         AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                                         AND e.id_institution = i_prof.institution
                                                         AND ei.id_episode = e.id_episode
                                                         AND l_epis_type IN (0, e.id_epis_type)) v1
                                               WHERE pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                                      i_prof,
                                                                                                                      v1.id_episode,
                                                                                                                      i_prof_cat_type,
                                                                                                                      l_hand_off_type),
                                                                                  i_prof.id) != -1
                                              UNION ALL
                                              SELECT v2.id_patient
                                                FROM (SELECT e.id_patient, ei.id_episode
                                                        FROM discharge d, episode e, epis_info ei
                                                       WHERE d.dt_admin_tstz >= l_dt_med_24
                                                         AND d.dt_cancel_tstz IS NULL
                                                         AND d.id_episode = e.id_episode
                                                         AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                                         AND e.id_institution = i_prof.institution
                                                         AND ei.id_episode = e.id_episode
                                                         AND l_epis_type IN (0, e.id_epis_type)) v2
                                               WHERE pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                                      i_prof,
                                                                                                                      v2.id_episode,
                                                                                                                      i_prof_cat_type,
                                                                                                                      l_hand_off_type),
                                                                                  i_prof.id) != -1
                                              UNION ALL
                                              SELECT v3.id_patient
                                                FROM (SELECT e.id_patient, ei.id_episode
                                                        FROM episode e, epis_info ei
                                                       WHERE e.dt_end_tstz >= l_dt_med_24
                                                         AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                                         AND e.id_institution = i_prof.institution
                                                         AND ei.id_episode = e.id_episode
                                                         AND l_epis_type IN (0, e.id_epis_type)) v3
                                               WHERE pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                                      i_prof,
                                                                                                                      v3.id_episode,
                                                                                                                      i_prof_cat_type,
                                                                                                                      l_hand_off_type),
                                                                                  i_prof.id) != -1)
                     ORDER BY name_pat;
            
                -- José Brito 15/05/2008 Support for ALERT® Triage
            ELSIF i_prof_cat_type IN (g_prof_cat_nurse, g_prof_cat_manchester)
            THEN
                g_error := 'OPEN O_EPIS_INACT 2';
                OPEN o_epis_inact FOR
                    WITH pat_list AS
                     (SELECT /*+ materialized */
                      DISTINCT t.id_patient
                        FROM (SELECT e.id_patient, e.id_episode
                                FROM discharge d
                                JOIN episode e
                                  ON d.id_episode = e.id_episode
                                JOIN epis_info ei
                                  ON ei.id_episode = e.id_episode
                               WHERE d.dt_med_tstz >= CAST(l_dt_med_24 AS TIMESTAMP WITH LOCAL TIME ZONE)
                                 AND d.dt_cancel_tstz IS NULL
                                 AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                 AND e.id_institution = i_prof.institution
                                 AND l_epis_type IN (0, e.id_epis_type)
                              UNION ALL
                              SELECT e.id_patient, e.id_episode
                                FROM discharge d
                                JOIN episode e
                                  ON d.id_episode = e.id_episode
                                JOIN epis_info ei
                                  ON ei.id_episode = e.id_episode
                               WHERE d.dt_admin_tstz >= CAST(l_dt_med_24 AS TIMESTAMP WITH LOCAL TIME ZONE)
                                 AND d.dt_cancel_tstz IS NULL
                                 AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                 AND e.id_institution = i_prof.institution
                                 AND l_epis_type IN (0, e.id_epis_type)
                              UNION ALL
                              SELECT e.id_patient, e.id_episode
                                FROM episode e
                                JOIN epis_info ei
                                  ON e.id_episode = ei.id_episode
                               WHERE e.dt_end_tstz >= CAST(l_dt_med_24 AS TIMESTAMP WITH LOCAL TIME ZONE)
                                 AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                 AND e.id_institution = i_prof.institution
                                 AND l_epis_type IN (0, e.id_epis_type)) t
                       WHERE (SELECT pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                      i_prof,
                                                                                                      t.id_episode,
                                                                                                      i_prof_cat_type,
                                                                                                      l_hand_off_type),
                                                                  i_prof.id)
                                FROM dual) != -1)
                    SELECT (SELECT COUNT(epis2.id_episode) counter
                              FROM episode epis2
                             WHERE epis2.flg_ehr = 'N'
                               AND epis2.flg_status IN (g_epis_inactive, g_epis_pending)
                               AND epis2.id_patient = pat.id_patient
                             GROUP BY epis2.id_patient) num_episode,
                           pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof.institution, i_prof.software) dt_birth_string,
                           pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) dt_birth,
                           pat.id_patient,
                           pk_adt.get_patient_name(i_lang, i_prof, pat.id_patient, pk_adt.g_true) name_pat,
                           -- ALERT-102882 Patient name used for sorting
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, pat.id_patient, NULL, NULL) name_pat_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon,
                           (SELECT location
                              FROM pat_soc_attributes
                             WHERE id_patient = pat.id_patient
                               AND id_institution = i_prof.institution) location
                      FROM patient pat
                      JOIN pat_list p
                        ON pat.id_patient = p.id_patient
                     ORDER BY name_pat;
            ELSE
                g_error := 'INVALID PROF CAT (' || i_prof_cat_type || ')';
                RAISE g_exception;
            END IF;
        ELSE
            -- Inactivos nas últimas 24 horas
            g_error := 'OPEN O_EPIS_INACT 3';
            OPEN o_epis_inact FOR
                SELECT (SELECT COUNT(epis2.id_episode) counter
                          FROM episode epis2
                         WHERE epis2.flg_ehr = 'N'
                           AND epis2.flg_status IN (g_epis_inactive, g_epis_pending)
                           AND epis2.id_patient = pat.id_patient
                         GROUP BY epis2.id_patient) num_episode,
                       pk_date_utils.dt_chr(i_lang, pat.dt_birth, i_prof.institution, i_prof.software) dt_birth_string,
                       pk_date_utils.date_send(i_lang, pat.dt_birth, i_prof) dt_birth,
                       pat.id_patient,
                       pk_adt.get_patient_name(i_lang, i_prof, pat.id_patient, pk_adt.g_false) name_pat,
                       -- ALERT-102882 Patient name used for sorting
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, pat.id_patient, NULL, NULL) name_pat_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon,
                       (SELECT location
                          FROM pat_soc_attributes
                         WHERE id_patient = pat.id_patient
                           AND id_institution = i_prof.institution) location
                  FROM patient pat
                 WHERE pat.id_patient IN (SELECT e.id_patient
                                            FROM discharge d
                                            JOIN episode e
                                              ON e.id_episode = d.id_episode
                                            LEFT JOIN episode e2
                                              ON e2.id_episode = e.id_prev_episode
                                           WHERE d.dt_med_tstz >= l_dt_med_24
                                             AND d.dt_cancel_tstz IS NULL
                                             AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                             AND l_epis_type IN (0, e.id_epis_type, e2.id_epis_type)
                                             AND e.id_institution = i_prof.institution
                                          UNION ALL
                                          SELECT e.id_patient
                                            FROM discharge d
                                            JOIN episode e
                                              ON e.id_episode = d.id_episode
                                            LEFT JOIN episode e2
                                              ON e2.id_episode = e.id_prev_episode
                                           WHERE d.dt_admin_tstz >= l_dt_med_24
                                             AND d.dt_cancel_tstz IS NULL
                                             AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                             AND l_epis_type IN (0, e.id_epis_type, e2.id_epis_type)
                                             AND e.id_institution = i_prof.institution
                                          UNION ALL
                                          SELECT e.id_patient
                                            FROM episode e
                                            LEFT JOIN episode e2
                                              ON e2.id_episode = e.id_prev_episode
                                           WHERE e.dt_end_tstz >= l_dt_med_24
                                             AND e.flg_status IN (g_epis_inactive, g_epis_pending)
                                             AND l_epis_type IN (0, e.id_epis_type, e2.id_epis_type)
                                             AND e.id_institution = i_prof.institution)
                 ORDER BY name_pat;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_inact);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_INACTIVE_24',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter todas as queixas de um episódio
    *
    * @param i_lang             language id
    * @param i_prof             professional, software and institution ids
    * @param i_episode          episode id
    *
    * @return                   description                            
    *
    * @author                   Emília Taborda
    * @version                  1.0 
    * @since                    2007/01/19
    *
    * @author                   José Silva
    * @version                  2.5.1.2
    * @since                    2010/10/27
    **********************************************************************************************/
    FUNCTION get_epis_anamnesis
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN CLOB IS
        l_eanam CLOB;
    
        l_cur_epis_complaint pk_complaint.epis_complaint_cur;
        l_row_epis_complaint pk_complaint.epis_complaint_rec;
        l_error              t_error_out;
        l_exception EXCEPTION;
        l_sep VARCHAR2(10);
    
    BEGIN
    
        g_error := 'GET EMERGENCY COMPLAINT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                               i_prof           => i_prof,
                                               i_episode        => i_episode,
                                               i_epis_docum     => NULL,
                                               i_flg_only_scope => pk_alert_constant.g_no,
                                               i_flg_single_row => pk_alert_constant.g_no,
                                               o_epis_complaint => l_cur_epis_complaint,
                                               o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
        pk_alertlog.log_debug(g_error);
        LOOP
            FETCH l_cur_epis_complaint
                INTO l_row_epis_complaint;
        
            EXIT WHEN l_cur_epis_complaint%NOTFOUND;
        
            IF l_row_epis_complaint.reg_type = pk_complaint.g_reg_type_complaint
            THEN
                l_eanam := l_eanam || l_sep ||
                           pk_complaint.get_epis_complaint_desc(i_lang,
                                                                i_prof,
                                                                l_row_epis_complaint.desc_complaint,
                                                                NULL,
                                                                pk_alert_constant.g_yes);
            ELSIF l_row_epis_complaint.reg_type = pk_complaint.g_reg_type_anamnesis
            THEN
                l_eanam := l_eanam || l_sep ||
                           pk_complaint.get_epis_complaint_desc_full(i_lang,
                                                                     i_prof,
                                                                     NULL,
                                                                     l_row_epis_complaint.patient_complaint_full,
                                                                     pk_alert_constant.g_yes);
            END IF;
        
            l_sep := '; ';
        
        END LOOP;
    
        CLOSE l_cur_epis_complaint;
    
        RETURN l_eanam;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END get_epis_anamnesis;
    --
    /**********************************************************************************************
    * Obter todas os diagnósticos de saída (finais) de um episódio (concatenação)
    *
    * @param i_episode          episode id        
    * @param i_institution      institution id      
    * @param i_software         software id
    *
    * @return                   description                            
    *
    * @author                   Emília Taborda
    * @version                  1.0 
    * @since                    2007/01/23
    **********************************************************************************************/
    FUNCTION get_epis_diag_concat
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_ediag VARCHAR2(30000);
        c_diags pk_types.cursor_type;
    BEGIN
        g_error := 'OPEN C_DIAGS';
        pk_alertlog.log_debug(g_error);
        -- José Brito 21/07/2009 Code refactoring
        SELECT pk_utils.concatenate_list(CURSOR (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                            i_prof                => profissional(NULL,
                                                                                                                  i_institution,
                                                                                                                  i_software),
                                                                            i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                                            i_id_diagnosis        => d.id_diagnosis,
                                                                            i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                            i_code                => d.code_icd,
                                                                            i_flg_other           => d.flg_other,
                                                                            i_flg_std_diag        => ad.flg_icd9,
                                                                            i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis
                                            FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
                                           WHERE ed.flg_type = g_epis_diag_type_definitive
                                             AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                                             AND ed.id_diagnosis = d.id_diagnosis
                                             AND ed.id_episode = i_episode
                                             AND ed.flg_status IN (g_epis_diag_confirmed, g_epis_diag_despiste)),
                                         '; ')
          INTO l_ediag
          FROM dual;
    
        RETURN l_ediag;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
    END;
    --
    /**********************************************************************************************
    * Registar a informação de chegada do episódio
    *
    * @param i_lang              the id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_epis           episode id        
    * @param i_dt_transportation Data do transporte
    * @param i_id_transp_entity  Transporte entidade
    * @param i_flg_time          E - início do episódio, S - alta administrativa, T - transporte s/ episódio
    * @param i_notes             Notes
    * @param i_origin            Origem
    * @param i_external_cause    external cause
    * @param i_companion         acompanhante
    * @param o_error             Error message
    *
    * @return                   TRUE if sucess, FALSE otherwise                            
    *
    * @author                   Luis Gaspar
    * @version                  1.0 
    * @since                    2007/02/21
    **********************************************************************************************/
    FUNCTION set_arrive
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        i_origin                IN visit.id_origin%TYPE,
        i_external_cause        IN visit.id_external_cause%TYPE,
        i_companion             IN epis_info.companion%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'SET ARRIVE';
        l_internal_error EXCEPTION;
        l_id_transportation transportation.id_transportation%TYPE;
    BEGIN
    
        g_error := 'CALL TO SET_ARRIVE_INTERNAL';
        IF NOT set_arrive_internal(i_lang                  => i_lang,
                                   i_prof                  => i_prof,
                                   i_id_epis               => i_id_epis,
                                   i_dt_transportation_str => i_dt_transportation_str,
                                   i_id_transp_entity      => i_id_transp_entity,
                                   i_flg_time              => i_flg_time,
                                   i_notes                 => i_notes,
                                   i_origin                => i_origin,
                                   i_external_cause        => i_external_cause,
                                   i_companion             => i_companion,
                                   i_internal_type         => 'A', -- This function is used only in the "Arrived by" screen.
                                   i_sysdate               => NULL,
                                   o_id_transportation     => l_id_transportation,
                                   o_error                 => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_arrive;

    /**********************************************************************************************
    * DATABASE INTERNAL FUNCION. Register the data about the arrival of the patient.
    *
    * @param i_lang              the id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_epis           episode id        
    * @param i_dt_transportation Data do transporte
    * @param i_id_transp_entity  Transporte entidade
    * @param i_flg_time          E - início do episódio, S - alta administrativa, T - transporte s/ episódio
    * @param i_notes             Notes
    * @param i_origin            Origem
    * @param i_external_cause    external cause
    * @param i_companion         acompanhante
    * @param i_internal_type     Called from (A) Arrived by (T) Triage
    * @param i_sysdate           Current date
    * @param o_error             Error message
    *
    * @return                   TRUE if sucess, FALSE otherwise                            
    *
    * @author                   José Brito (using SET_ARRIVE by Luís Gaspar)
    * @version                  2.6.0
    * @since                    2009/12/07
    **********************************************************************************************/
    FUNCTION set_arrive_internal
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        i_origin                IN visit.id_origin%TYPE,
        i_external_cause        IN visit.id_external_cause%TYPE,
        i_companion             IN epis_info.companion%TYPE,
        i_internal_type         IN VARCHAR2, -- (A) Arrived by (T) Triage
        i_sysdate               IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_id_transportation     OUT transportation.id_transportation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(200) := 'SET ARRIVE_INTERNAL';
        l_rowids_ei    table_varchar;
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_id_transp_entity transp_entity.id_transp_entity%TYPE;
        l_origin           origin.id_origin%TYPE;
        l_notes            transportation.notes%TYPE;
        l_external_cause   external_cause.id_external_cause%TYPE;
        l_companion        epis_info.companion%TYPE;
    
        l_id_transportation_old transportation.id_transportation%TYPE;
    BEGIN
        l_sysdate_tstz := nvl(i_sysdate, current_timestamp);
    
        --check if an external cause exists (for coding proposes)
        BEGIN
            SELECT t.id_transportation
              INTO l_id_transportation_old
              FROM transportation t
             WHERE t.id_episode = i_id_epis
               AND t.id_external_cause IS NOT NULL
               AND rownum <= 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_transportation_old := NULL;
        END;
    
        IF i_internal_type = 'T'
        THEN
            -- If registered during triage, get the most recent notes, external cause and companion, to avoid loss of data.
            -- If transportation and origin are set to NULL during triage, keep the previous values.
            g_error := 'GET TRANSPORTATION DATA';
            SELECT nvl(i_id_transp_entity, tr.id_transp_entity),
                   coalesce(i_origin, tr.id_origin, v.id_origin),
                   nvl(i_notes, tr.notes),
                   nvl(nvl(i_external_cause, tr.id_external_cause), v.id_external_cause),
                   ei.companion
              INTO l_id_transp_entity, l_origin, l_notes, l_external_cause, l_companion
              FROM transportation tr, epis_info ei, episode e, visit v
             WHERE ei.id_episode = i_id_epis
               AND ei.id_episode = e.id_episode
               AND e.id_visit = v.id_visit
               AND ei.id_episode = tr.id_episode(+)
               AND ((tr.dt_transportation_tstz = (SELECT MAX(tt.dt_transportation_tstz)
                                                    FROM transportation tt
                                                   WHERE tt.id_episode = i_id_epis)) OR
                   tr.dt_transportation_tstz IS NULL);
        
        ELSE
            l_id_transp_entity := i_id_transp_entity;
            l_origin           := i_origin;
            l_notes            := i_notes;
            l_external_cause   := i_external_cause;
            l_companion        := i_companion;
        END IF;
    
        IF (i_internal_type = 'T' AND nvl(l_id_transp_entity, -1) <> -1)
           OR (i_internal_type = 'T' AND (i_external_cause IS NOT NULL OR i_notes IS NOT NULL))
           OR (i_internal_type = 'A' AND (l_id_transp_entity IS NOT NULL OR l_origin IS NOT NULL OR
           l_external_cause IS NOT NULL OR l_companion IS NOT NULL)) -- José Brito 29/05/2009 ALERT-30519 CCHIT: add history to "Arrived by"
        THEN
            g_error := 'CALL TO CREATE_TRANSPORTATION_INTERNAL';
            IF NOT create_transportation_internal(i_lang,
                                                  i_prof,
                                                  i_id_epis,
                                                  i_dt_transportation_str,
                                                  l_id_transp_entity,
                                                  i_flg_time,
                                                  l_notes,
                                                  -- José Brito 29/05/2009 ALERT-30519 CCHIT: add history to "Arrived by"
                                                  l_origin,
                                                  l_external_cause,
                                                  l_companion,
                                                  l_sysdate_tstz,
                                                  o_id_transportation,
                                                  o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        END IF;
    
        g_error := 'SET VISIT INFO';
        UPDATE visit
           SET id_origin = l_origin, id_external_cause = l_external_cause
         WHERE id_visit = (SELECT id_visit
                             FROM episode
                            WHERE id_episode = i_id_epis);
    
        g_error := 'SET EPIS_INFO INFO';
        ts_epis_info.upd(id_episode_in => i_id_epis,
                         companion_in  => l_companion,
                         companion_nin => FALSE,
                         desc_info_in  => l_notes,
                         rows_out      => l_rowids_ei);
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_INFO', l_rowids_ei, o_error);
    
        IF i_dep_clin_serv IS NOT NULL
        THEN
            IF NOT set_epis_clin_serv(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_episode       => i_id_epis,
                                      i_dep_clin_serv => i_dep_clin_serv,
                                      o_error         => o_error)
            THEN
                RAISE e_call_exception;
            END IF;
        END IF;
    
        -- update ADT information related with the arrived by
        IF NOT pk_adt.update_admission_adt(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_episode       => i_id_epis,
                                           i_origin        => i_origin,
                                           i_ext_cause     => i_external_cause,
                                           i_transp_entity => i_id_transp_entity,
                                           i_notes         => i_notes,
                                           o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Notify inter_alert the existence of the new transportation
        IF l_id_transportation_old IS NULL
           AND l_external_cause IS NOT NULL
        THEN
            pk_ia_event_common.external_cause_new(i_id_institution    => i_prof.institution,
                                                  i_id_transportation => o_id_transportation,
                                                  i_id_episode        => i_id_epis);
        ELSIF l_id_transportation_old IS NOT NULL
        THEN
            pk_ia_event_common.external_cause_update(i_id_institution    => i_prof.institution,
                                                     i_id_transportation => o_id_transportation,
                                                     i_id_episode        => i_id_epis);
        END IF;
        --
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_call_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_arrive_internal;
    --
    /**********************************************************************************************
    * Show history of all records added in "Arrived by".
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis                Episode ID
    * @param o_detail                 "Arrived by" history
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito
    * @version                        1.0 
    * @since                          2009/05/29
    **********************************************************************************************/
    FUNCTION get_arrived_by_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET DETAILS';
        pk_alertlog.log_debug(g_error);
        OPEN o_detail FOR
            SELECT tr.id_transportation,
                   tr.flg_time,
                   -- Professional + Date
                   tr.id_professional,
                   (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, tr.id_professional)
                      FROM dual) prof_name,
                   (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            tr.id_professional,
                                                            decode(tr.dt_creation,
                                                                   NULL,
                                                                   tr.dt_transportation_tstz,
                                                                   tr.dt_creation),
                                                            tr.id_episode)
                      FROM dual) spec_name,
                   -- The previous DB model used DT_TRANSPORTATION as the creation date
                   decode(tr.dt_creation,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang,
                                                      tr.dt_transportation_tstz,
                                                      i_prof.institution,
                                                      i_prof.software),
                          pk_date_utils.date_char_tsz(i_lang, tr.dt_creation, i_prof.institution, i_prof.software)) dt_creation,
                   -- Transport Entity
                   tr.id_transp_entity,
                   pk_translation.get_translation(i_lang, te.code_transp_entity) transp_entity,
                   -- Transportation Date
                   pk_date_utils.date_char_tsz(i_lang, tr.dt_transportation_tstz, i_prof.institution, i_prof.software) dt_transportation,
                   -- Origin
                   tr.id_origin,
                   decode(tr.id_origin,
                          NULL,
                          decode(v.id_origin,
                                 NULL,
                                 NULL,
                                 (SELECT pk_translation.get_translation(i_lang, o1.code_origin)
                                    FROM origin o1
                                   WHERE o1.id_origin = v.id_origin)),
                          pk_translation.get_translation(i_lang, o.code_origin)) origin_desc,
                   -- External Cause
                   tr.id_external_cause,
                   decode(tr.id_external_cause,
                          NULL,
                          -- José Brito 21/07/2010
                          decode(v.id_external_cause,
                                 NULL,
                                 NULL,
                                 (SELECT pk_translation.get_translation(i_lang, ec1.code_external_cause)
                                    FROM external_cause ec1
                                   WHERE ec1.id_external_cause = v.id_external_cause)),
                          pk_translation.get_translation(i_lang, ec.code_external_cause)) external_cause_desc,
                   -- Companion
                   tr.companion,
                   -- Notes
                   tr.notes,
                   pk_adt.get_admission_institution(i_lang, epis.id_episode) admission_inst
              FROM transportation tr, transp_entity te, external_cause ec, origin o, visit v, episode epis
             WHERE te.id_transp_entity = tr.id_transp_entity
               AND tr.id_external_cause = ec.id_external_cause(+)
               AND tr.id_origin = o.id_origin(+)
               AND tr.id_episode = i_id_epis
               AND epis.id_episode = i_id_epis
               AND epis.id_visit = v.id_visit
             ORDER BY tr.dt_creation DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_ARRIVED_BY_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_detail);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_arrived_by_detail;
    --
    /**********************************************************************************************
    * Listar o detalhe da informação de chegada do episódio.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param o_arrive                 cursor with toda a informação associada à chegada do episódio   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luis Gaspar
    * @version                        1.0 
    * @since                          2007/02/22
    **********************************************************************************************/
    FUNCTION get_arrive
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_arrive  OUT cursor_arrive,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient        patient.id_patient%TYPE;
        l_emergency_contact epis_triage.emergency_contact%TYPE;
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error);
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_id_epis;
    
        g_error := 'GET PATIENT EMERGENCY CONTACT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_adt.get_emergency_contact(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => l_id_patient,
                                            o_contact => l_emergency_contact,
                                            o_error   => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        g_error := 'GET CURSOR O_ARRIVE';
        OPEN o_arrive FOR
            SELECT tr.id_transportation,
                   tr.dt_transportation_tstz,
                   tr.id_professional,
                   tr.id_transp_entity,
                   pk_translation.get_translation(i_lang, te.code_transp_entity) transp_entity,
                   tr.flg_time,
                   tr.notes,
                   v.id_external_cause,
                   decode(v.id_external_cause,
                          NULL,
                          NULL,
                          pk_translation.get_translation(i_lang, ec.code_external_cause)) external_cause_desc,
                   v.id_origin,
                   decode(v.id_origin, NULL, NULL, pk_translation.get_translation(i_lang, o.code_origin)) origin_desc,
                   ei.companion,
                   -- Detail button is only available if exists previous records in this screen,
                   -- or if transport entity exists
                   decode(tr.id_transp_entity, NULL, 'N', 'Y') flg_show_detail,
                   -- José Brito 21/01/2010 ALERT-16615 Data registered in triage
                   et.flg_letter,
                   decode(et.flg_letter, NULL, '', pk_sysdomain.get_domain('YES_NO', et.flg_letter, i_lang)) desc_letter,
                   decode(et.desc_origin, NULL, '', et.desc_origin) triage_origin_desc,
                   l_emergency_contact emergency_contact
              FROM transportation tr,
                   transp_entity  te,
                   episode        e,
                   visit          v,
                   epis_info      ei,
                   external_cause ec,
                   origin         o,
                   epis_triage    et
             WHERE tr.id_episode(+) = e.id_episode
               AND te.id_transp_entity(+) = tr.id_transp_entity
               AND (tr.dt_transportation_tstz IN (SELECT MAX(tt.dt_transportation_tstz)
                                                    FROM transportation tt
                                                   WHERE tt.id_episode = i_id_epis) OR
                    tr.dt_transportation_tstz IS NULL)
                  -- To return the data registered in triage, we need the most recent NON-ROUTINE triage.
               AND (et.dt_end_tstz IN (SELECT MAX(et1.dt_end_tstz)
                                         FROM epis_triage et1
                                        WHERE et1.id_episode = i_id_epis
                                          AND et1.id_triage_white_reason IS NULL)
                    -- Patient only has routine triages.
                    OR et.dt_end_tstz IN (SELECT MAX(et1.dt_end_tstz)
                                            FROM epis_triage et1
                                           WHERE et1.id_episode = i_id_epis
                                             AND et1.id_triage_white_reason IS NOT NULL
                                             AND NOT EXISTS (SELECT 0
                                                    FROM epis_triage et2
                                                   WHERE et2.id_episode = i_id_epis
                                                     AND et2.id_triage_white_reason IS NULL))
                    -- Patient doesn't have triages.
                     OR et.id_epis_triage IS NULL)
               AND et.id_episode(+) = e.id_episode
               AND e.id_episode = i_id_epis
               AND v.id_visit = e.id_visit
               AND ei.id_episode = e.id_episode
               AND v.id_external_cause = ec.id_external_cause(+)
               AND v.id_origin = o.id_origin(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_ARRIVE',
                                              o_error);
            open_my_cursor(o_arrive);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_ARRIVE',
                                              o_error);
            open_my_cursor(o_arrive);
            RETURN FALSE;
    END get_arrive;
    --
    /**********************************************************************************************
    * Listar todos os episódios INACTIVOS de urgência ou com origem na urgência (obs)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_epis_inact             array with inactive episodes admin
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_flg_show                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luis Gaspar
    * @version                        1.0 
    * @since                          2007/02/23
    **********************************************************************************************/
    FUNCTION get_epis_inactive_admin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_inact      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error t_error_out;
        e_call_exception EXCEPTION;
    BEGIN
        RETURN get_epis_inactive(i_lang,
                                 i_prof,
                                 i_id_sys_btn_crit,
                                 i_crit_val,
                                 i_dt,
                                 o_msg,
                                 o_msg_title,
                                 o_button,
                                 o_epis_inact,
                                 o_mess_no_result,
                                 o_flg_show,
                                 o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_inact);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_INACTIVE_ADMIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END get_epis_inactive_admin;
    --
    /**********************************************************************************************
    * Listar todos os episódios INACTIVOS para um determinado paciente que pertencem ao tipo de episódio associado ao software que realiza o pedido
      ou têm origem num episódio com tipo de episódio associado ao software que realiza o pedido
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id             
    * @param o_epis_inact             cursor with episodes inactives                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luis Gaspar
    * @version                        1.0 
    * @since                          2007-02-22
    * @notes                          Os episódios que podem ter notas pós-alta são: os que têm origem no software (I_PROF.SOFTWARE)
                                                                                     ou que têm como EPISODE.ID_EPISODE_ORIGIN um episódio originado 
                                                                                     no software (I_PROF_.SOFTWARE).
                                      Nem todas as categorias de profissionais podem fazer reaberturas.Essa validação é feita posteriormente.
                                      Não considerar altas canceladas.
    **********************************************************************************************/
    FUNCTION get_epis_pat_inactive_admin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        o_epis_inact OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_epis_pat_inactive(i_lang, i_prof, i_patient, o_epis_inact, o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_inact);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_PAT_INACTIVE_ADMIN',
                                              o_error);
            RETURN FALSE;
    END get_epis_pat_inactive_admin;
    --
    /**********************************************************************************************
    * Listar todos os meus episódios INACTIVOS nas últimas 24 horas para um determinado paciente
      que pertencem ao tipo de episódio associado ao software que realiza o pedido
      ou têm origem num episódio com tipo de episódio associado ao software que realiza o pedido
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_type_inactive          Tipo de pesquisa de inactivos:MI24 - Meus doentes nas últimas 24 horas
                                                                    I24 -  doentes nas últimas 24 horas             
    * @param i_prof_cat_type          professional categoty
    * @param o_epis_inact             cursor with episodes inactives                
    * @param o_error                  Error message
    *
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luis Gaspar
    * @version                        1.0 
    * @since                          2007/02/23
    **********************************************************************************************/
    FUNCTION get_epis_inactive_24_admin
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_inactive IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_epis_inact    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type epis_type.id_epis_type%TYPE;
        l_dt_med_24 discharge.dt_med_tstz%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_dt_med_24    := current_timestamp - 1;
        g_error        := 'GET EPIS TYPE';
        BEGIN
            SELECT id_epis_type
              INTO l_epis_type
              FROM epis_type_soft_inst
             WHERE id_software = i_prof.software
               AND id_institution = i_prof.institution;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- Inactivos nas últimas 24 horas
        g_error := 'OPEN O_EPIS_INACT';
        OPEN o_epis_inact FOR
            SELECT pk_edis_proc.get_prev_episode(i_lang, v.id_patient, i_prof.institution, i_prof.software) +
                   (SELECT COUNT(0)
                      FROM episode e
                     WHERE e.flg_status = g_epis_inactive
                       AND e.id_institution = i_prof.institution
                       AND e.id_patient = p.id_patient) num_episode,
                   pk_date_utils.dt_chr(i_lang, p.dt_birth, i_prof.institution, i_prof.software) dt_birth_string,
                   pk_date_utils.date_send(i_lang, p.dt_birth, i_prof) dt_birth,
                   p.id_patient,
                   pk_adt.get_patient_name(i_lang, i_prof, p.id_patient, pk_adt.g_false) name_pat,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, NULL, NULL) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   (SELECT location
                      FROM pat_soc_attributes s
                     WHERE s.id_patient = p.id_patient
                       AND s.id_institution = i_prof.institution) location
              FROM (SELECT e.id_patient, e.id_episode, e.dt_end_tstz
                      FROM episode e
                     WHERE e.flg_status = pk_alert_constant.g_inactive
                          -- José Brito 17/07/2008 Mostrar episódios de OBS
                       AND e.id_epis_type = decode((SELECT pk_inp_episode.check_obs_episode(i_lang, i_prof, e.id_episode)
                                                     FROM dual),
                                                   0,
                                                   nvl(l_epis_type, e.id_epis_type),
                                                   pk_alert_constant.g_epis_type_inpatient)
                       AND e.id_institution = i_prof.institution
                       AND e.dt_end_tstz >= l_dt_med_24
                    UNION ALL
                    SELECT e.id_patient, e.id_episode, e.dt_end_tstz
                      FROM episode e
                     WHERE e.flg_status = pk_alert_constant.g_inactive
                          -- José Brito 17/07/2008 Mostrar episódios de OBS
                       AND e.id_prev_epis_type =
                           decode((SELECT pk_inp_episode.check_obs_episode(i_lang, i_prof, e.id_prev_episode)
                                    FROM dual),
                                  0,
                                  nvl(l_epis_type, e.id_prev_epis_type),
                                  pk_alert_constant.g_epis_type_inpatient)
                       AND e.id_institution = i_prof.institution
                       AND e.dt_end_tstz >= l_dt_med_24) v,
                   discharge d,
                   patient p
             WHERE d.id_episode = v.id_episode
               AND nvl(pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, d.flg_status_adm, d.dt_admin_tstz),
                       v.dt_end_tstz) >= l_dt_med_24
               AND d.dt_cancel_tstz IS NULL
               AND v.id_patient = p.id_patient
             GROUP BY dt_birth, v.id_patient, p.id_patient
             ORDER BY name_pat;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_inact);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_INACTIVE_24_ADMIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_epis_inactive_24_admin;
    --
    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para pessoal administrativo
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category       
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    cursor with active patient
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Luis Gaspar
    * @version                        1.0 
    * @since                          2006/02/26
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_admin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where VARCHAR2(4000);
        l_from  VARCHAR2(32767);
        l_hint  VARCHAR2(32767);
        l_limit sys_config.desc_sys_config%TYPE;
        l_date  VARCHAR2(40);
    
        l_prof_cat     category.flg_type%TYPE;
        l_sysdate_char VARCHAR2(32);
    
    BEGIN
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show     := 'N';
        g_sysdate      := SYSDATE;
        --
        l_limit    := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        --
        l_where := NULL;
        l_date  := to_char(trunc(nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL), current_timestamp)),
                           'YYYYMMDD');
        --
        g_error := 'GET WHERE';
        IF (NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                    i_crit_val => i_crit_val,
                                    i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    o_where    => l_where))
        THEN
            l_where := NULL;
        END IF;
        --  
        g_error := 'GET FROM';
        IF (NOT pk_search.get_from(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   o_from     => l_from,
                                   o_hint     => l_hint))
        THEN
            l_from := NULL;
        END IF;
        --
    
        -- 1º select vai sobre os episódios de urgência
        -- 2º select vai sobre os episódios de OBS
        g_error      := 'OPEN O_PAT ';
        g_no_results := FALSE;
        g_overlimit  := FALSE;
        --
        g_error := 'SET NLS';
    
        OPEN o_pat FOR --
            SELECT *
              FROM TABLE(tf_pat_criteria_active_admin(i_lang, i_prof, l_where, l_from, l_hint));
    
        IF g_overlimit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF g_no_results
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
        
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_PAT_CRITERIA_ACTIVE_ADMIN', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_PAT_CRITERIA_ACTIVE_ADMIN', o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_PAT_CRITERIA_ACTIVE_ADMIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_pat_criteria_active_admin;

    FUNCTION tf_pat_criteria_active_admin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_patcriteriaactiveadmin IS
        l_error        t_error_out;
        dataset        pk_types.cursor_type;
        l_limit        sys_config.desc_sys_config%TYPE;
        l_sysdate_char VARCHAR2(32);
        l_prof_cat     category.flg_type%TYPE;
        out_obj        t_rec_patcriteriaactiveadmin := t_rec_patcriteriaactiveadmin(origem                   => NULL,
                                                                                    acuity                   => NULL,
                                                                                    color_text               => NULL,
                                                                                    rank_acuity              => NULL,
                                                                                    id_episode               => NULL,
                                                                                    id_patient               => NULL,
                                                                                    care_stage               => NULL,
                                                                                    dt_server                => NULL,
                                                                                    pat_age                  => NULL,
                                                                                    gender                   => NULL,
                                                                                    photo                    => NULL,
                                                                                    name_pat                 => NULL,
                                                                                    name_pat_sort            => NULL,
                                                                                    pat_ndo                  => NULL,
                                                                                    pat_nd_icon              => NULL,
                                                                                    num_clin_record          => NULL,
                                                                                    attaches                 => NULL,
                                                                                    transfer_req_time        => NULL,
                                                                                    dt_begin                 => NULL,
                                                                                    inp_admission_time       => NULL,
                                                                                    disch_pend_time          => NULL,
                                                                                    disch_time               => NULL,
                                                                                    dt_follow_up_date        => NULL,
                                                                                    label_follow_up_date     => NULL,
                                                                                    hour_mask_follow_up_date => NULL,
                                                                                    date_mask_follow_up_date => NULL,
                                                                                    rank                     => NULL,
                                                                                    flg_cancel               => NULL,
                                                                                    color_dt_begin           => NULL,
                                                                                    pat_age_for_order_by     => NULL,
                                                                                    fast_track_icon          => NULL,
                                                                                    fast_track_color         => NULL,
                                                                                    fast_track_status        => NULL,
                                                                                    esi_level                => NULL);
    
        CURSOR l_cur IS
            SELECT 1 position, t.*
              FROM v_src_edis_active_admin t;
    
        TYPE dataset_tt IS TABLE OF l_cur%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset              dataset_tt;
        l_row                  PLS_INTEGER := 1;
        RESULT                 t_coll_patcriteriaactiveadmin := t_coll_patcriteriaactiveadmin();
        l_task_arrival         TIMESTAMP WITH LOCAL TIME ZONE;
        l_test1                VARCHAR2(10);
        l_test2                TIMESTAMP WITH LOCAL TIME ZONE;
        l_test3                TIMESTAMP WITH LOCAL TIME ZONE;
        l_msg_edis_grid_t054   sys_message.desc_message%TYPE;
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t003 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
    
        l_screens table_varchar := table_varchar('ADMIN_DISCHARGE', 'PATIENT_ARRIVAL');
    
        l_has_transfer  NUMBER(6);
        l_ft_type       fast_track.icon%TYPE;
        l_id_fast_track fast_track.id_fast_track%TYPE;
    
        l_query VARCHAR2(32767);
    
    BEGIN
        --
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        g_error        := 'SET VARIABLES';
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
    
        pk_context_api.set_parameter('g_sysdate_tstz', g_sysdate_tstz);
        pk_context_api.set_parameter('g_epis_pending', g_epis_pending);
        pk_context_api.set_parameter('g_epis_active', g_epis_active);
        pk_context_api.set_parameter('g_cancelled', g_cancelled); -- José Brito 09/02/09 ALERT-9546
        pk_context_api.set_parameter('g_epis_inactive', g_epis_inactive);
        pk_context_api.set_parameter('g_no_triage_color_id', g_no_triage_color_id);
        pk_context_api.set_parameter('g_discharge_flg_status_active', g_discharge_flg_status_active);
        pk_context_api.set_parameter('g_discharge_flg_status_pend', g_discharge_flg_status_pend);
        pk_context_api.set_parameter('g_episode_flg_type_temp', g_episode_flg_type_temp);
        pk_context_api.set_parameter('g_episode_flg_type_def', g_episode_flg_type_def);
        pk_context_api.set_parameter('g_epis_type_urg', g_epis_type_urg);
        pk_context_api.set_parameter('g_epis_type_inp', g_epis_type_inp);
        pk_context_api.set_parameter('g_no_color_rank', g_no_color_rank);
        pk_context_api.set_parameter('g_no_triage', g_no_triage);
        pk_context_api.set_parameter('g_no_triage_color_text', g_no_triage_color_text);
        pk_context_api.set_parameter('g_transfer_inst_transp', g_transfer_inst_transp);
    
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
    
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
        --
        g_error := 'CALL PK_ACCESS.PRELOAD_SHORTCUTS';
        IF NOT
            pk_access.preload_shortcuts(i_lang => i_lang, i_prof => i_prof, i_screens => l_screens, o_error => l_error)
        THEN
            RETURN RESULT;
        END IF;
        --
        l_query := 'SELECT ' || nvl(i_hint, 'NULL position, ') || 't.* ' || --
                   ' FROM v_src_edis_active_admin t ' || i_from || --
                   ' WHERE rownum <= :limit + 1 ' || i_where || ' ' || ' ORDER BY position, dt_rank, name_pat';
        --
        g_error := 'OPEN DATASET';
        OPEN dataset FOR l_query
            USING l_limit;
    
        l_msg_edis_grid_t054   := pk_message.get_message(i_lang, 'EDIS_GRID_T054');
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t003 := pk_message.get_message(i_lang, 'EDIS_COMMON_T003');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
        --
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
        --
        g_error := 'COUNT RESULTS';
        IF (l_dataset.count > l_limit)
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0)
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF (l_dataset.count < l_limit)
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        --
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        WHILE (l_row <= result.count)
        LOOP
        
            l_task_arrival := pk_transfer_institution.get_grid_task_arrival(i_lang, i_prof, l_dataset(l_row).id_episode);
            IF (l_task_arrival IS NULL)
            THEN
                l_test1 := pk_ubu.get_episode_transportation(l_dataset(l_row).id_episode, i_prof);
            ELSE
                l_test1 := 'T';
            END IF;
        
            IF (l_dataset(l_row).flg_status_d IS NULL)
            THEN
                IF (l_test1 = 'T')
                THEN
                    l_test2 := l_task_arrival;
                ELSE
                    IF (l_test1 = 'Y')
                    THEN
                        l_test2 := pk_ubu.get_date_transportation(l_dataset(l_row).id_episode);
                    ELSIF (l_test1 = 'N')
                    THEN
                        l_test2 := NULL;
                    ELSE
                        IF l_dataset(l_row).dt_first_obs_tstz IS NULL
                        THEN
                            l_test2 := l_dataset(l_row).dt_begin_tstz;
                        ELSE
                            l_test2 := NULL;
                        END IF;
                    END IF;
                END IF;
            
            ELSE
                IF (l_dataset(l_row).flg_status_d = g_discharge_flg_status_reopen)
                THEN
                    IF (l_dataset(l_row).dt_first_obs_tstz IS NULL)
                    THEN
                        l_test2 := CASE l_test1
                                       WHEN 'T' THEN
                                        l_task_arrival
                                       WHEN 'Y' THEN
                                        pk_ubu.get_date_transportation(l_dataset(l_row).id_episode)
                                       WHEN 'N' THEN
                                        NULL
                                       ELSE
                                        l_dataset(l_row).dt_begin_tstz
                                   END;
                    END IF;
                END IF;
            END IF;
        
            IF (l_dataset(l_row).query = 1)
            THEN
            
                IF (l_test1 IS NULL)
                THEN
                    IF (i_prof.software = g_soft_edis)
                    THEN
                        out_obj.origem := l_msg_edis_common_t002;
                    ELSE
                        out_obj.origem := l_msg_edis_common_t004;
                    END IF;
                ELSIF l_test1 = 'T'
                THEN
                    out_obj.origem := l_msg_edis_common_t002;
                ELSE
                    out_obj.origem := l_msg_edis_common_t004;
                END IF;
            
                l_test3                    := CASE l_dataset(l_row).flg_type_epis_obs
                                                  WHEN g_episode_flg_type_temp THEN
                                                   pk_date_utils.add_to_ltstz(l_dataset(l_row).dt_begin_tstz_obs, 1)
                                              END;
                out_obj.inp_admission_time := pk_date_utils.date_send_tsz(i_lang, l_test3, i_prof);
            
                out_obj.disch_pend_time := CASE l_dataset(l_row).flg_status_d
                                               WHEN g_discharge_flg_status_pend THEN
                                                pk_date_utils.date_send_tsz(i_lang,
                                                                            nvl(l_dataset(l_row).dt_med_tstz,
                                                                                l_dataset(l_row).dt_pend_tstz),
                                                                            i_prof)
                                           END;
            
                out_obj.disch_time := CASE l_dataset(l_row).flg_status_epis
                                          WHEN g_epis_pending THEN
                                           (CASE l_dataset(l_row).flg_type_epis_obs
                                               WHEN g_episode_flg_type_temp THEN
                                                NULL
                                               ELSE
                                                pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_med_tstz, i_prof)
                                           END)
                                      END;
            
                out_obj.rank       := pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_rank, i_prof);
                out_obj.id_episode := pk_edis_grid.get_admin_id_episode(i_lang,
                                                                        i_prof,
                                                                        l_dataset(l_row).id_episode,
                                                                        l_dataset(l_row).id_episode_obs);
            
                out_obj.label_follow_up_date := CASE
                                                    WHEN l_dataset(l_row).follow_up_date_tstz IS NULL THEN
                                                     pk_edis_grid.get_label_follow_up_date(i_lang,
                                                                                           i_prof,
                                                                                           l_dataset(l_row).id_disch_reas_dest,
                                                                                           l_prof_cat)
                                                    ELSE
                                                     l_msg_edis_grid_t054
                                                END;
            ELSE
                IF (l_dataset(l_row).query = 2)
                THEN
                    out_obj.origem := l_msg_edis_common_t003;
                
                    IF l_dataset(l_row).flg_status_prev = g_epis_inactive
                        AND l_dataset(l_row).flg_status_d IS NULL
                    THEN
                        out_obj.inp_admission_time := pk_date_utils.date_send_tsz(i_lang,
                                                                                  pk_date_utils.add_to_ltstz(l_dataset(l_row).dt_begin_tstz,
                                                                                                             1),
                                                                                  i_prof);
                    ELSE
                        out_obj.inp_admission_time := NULL;
                    END IF;
                
                    out_obj.disch_pend_time := CASE l_dataset(l_row).flg_status_d
                                                   WHEN g_discharge_flg_status_pend THEN
                                                    pk_date_utils.date_send_tsz(i_lang,
                                                                                nvl(l_dataset(l_row).dt_med_tstz,
                                                                                    l_dataset(l_row).dt_pend_tstz),
                                                                                i_prof)
                                                   ELSE
                                                    NULL
                                               END;
                    out_obj.disch_time      := pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_med_tstz, i_prof);
                    out_obj.rank := pk_date_utils.date_send_tsz(i_lang,
                                                                CASE l_dataset(l_row).flg_status_epis
                                                                    WHEN g_epis_pending THEN
                                                                     l_dataset(l_row).dt_med_tstz
                                                                    ELSE
                                                                     CASE
                                                                         WHEN l_dataset(l_row).dt_first_obs_tstz IS NULL THEN
                                                                          l_dataset(l_row).dt_begin_tstz
                                                                     END
                                                                END,
                                                                i_prof);
                
                    out_obj.id_episode := l_dataset(l_row).id_episode;
                
                    out_obj.label_follow_up_date := CASE
                                                        WHEN l_dataset(l_row).flg_status_prev = g_epis_inactive
                                                              AND l_dataset(l_row).flg_status_d IS NULL THEN
                                                         pk_edis_grid.get_label_follow_up(i_lang,
                                                                                          i_prof,
                                                                                          l_dataset(l_row).id_episode_prev,
                                                                                          l_prof_cat)
                                                        ELSE
                                                         NULL
                                                    END;
                END IF;
            END IF;
        
            out_obj.dt_begin        := pk_date_utils.date_send_tsz(i_lang, l_test2, i_prof);
            out_obj.color_dt_begin  := CASE l_test1
                                           WHEN 'Y' THEN
                                            g_ubu_color
                                           WHEN 'T' THEN
                                            'X'
                                           ELSE
                                            'N'
                                       END;
            out_obj.acuity          := l_dataset(l_row).acuity;
            out_obj.color_text      := l_dataset(l_row).color_text;
            out_obj.rank_acuity     := l_dataset(l_row).rank_acuity;
            out_obj.id_patient      := l_dataset(l_row).id_patient;
            out_obj.care_stage      := pk_patient_tracking.get_care_stage_grid_status(i_lang,
                                                                                      i_prof,
                                                                                      l_dataset(l_row).id_episode,
                                                                                      l_sysdate_char);
            out_obj.dt_server       := l_sysdate_char;
            out_obj.name_pat        := l_dataset(l_row).name_pat;
            out_obj.name_pat_sort   := l_dataset(l_row).name_pat_sort;
            out_obj.pat_ndo         := l_dataset(l_row).pat_ndo;
            out_obj.pat_nd_icon     := l_dataset(l_row).pat_nd_icon;
            out_obj.num_clin_record := l_dataset(l_row).num_clin_record;
        
            out_obj.pat_age              := pk_patient.get_pat_age(i_lang,
                                                                   l_dataset         (l_row).dt_birth,
                                                                   l_dataset         (l_row).dt_deceased,
                                                                   l_dataset         (l_row).age,
                                                                   i_prof.institution,
                                                                   i_prof.software);
            out_obj.pat_age_for_order_by := pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                                       i_prof    => i_prof,
                                                                                       i_type    => pk_edis_proc.g_sort_type_age,
                                                                                       i_episode => l_dataset(l_row).id_episode);
            out_obj.gender               := pk_patient.get_gender(i_lang, l_dataset(l_row).gender);
            out_obj.photo                := pk_patphoto.get_pat_photo(i_lang,
                                                                      i_prof,
                                                                      l_dataset(l_row).id_patient,
                                                                      l_dataset(l_row).id_episode,
                                                                      NULL);
            out_obj.attaches             := pk_doc.get_num_episode_images(l_dataset(l_row).id_episode,
                                                                          l_dataset(l_row).id_patient);
            out_obj.flg_cancel           := pk_visit.check_flg_cancel(i_lang, i_prof, l_dataset(l_row).id_episode);
        
            out_obj.transfer_req_time := nvl(pk_transfer_institution.get_grid_task_departure(i_lang,
                                                                                             i_prof,
                                                                                             l_dataset(l_row).id_episode),
                                             CASE l_test1
                                                 WHEN 'N' THEN
                                                  pk_access.get_shortcut('PATIENT_ARRIVAL') || '|' ||
                                                  pk_date_utils.date_send_tsz(i_lang,
                                                                              l_dataset(l_row).dt_begin_tstz,
                                                                              i_prof) || '|' || 'R' || '|' || 'X'
                                                 ELSE
                                                  NULL
                                             END);
        
            IF (l_dataset(l_row).flg_status_epis = g_epis_pending)
            THEN
                out_obj.dt_follow_up_date        := pk_date_utils.date_send_tsz(i_lang,
                                                                                l_dataset(l_row).follow_up_date_tstz,
                                                                                i_prof);
                out_obj.hour_mask_follow_up_date := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                     l_dataset(l_row).follow_up_date_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software);
                out_obj.date_mask_follow_up_date := pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                                          l_dataset(l_row).follow_up_date_tstz,
                                                                                          i_prof);
            ELSE
                out_obj.dt_follow_up_date        := NULL;
                out_obj.hour_mask_follow_up_date := NULL;
                out_obj.date_mask_follow_up_date := NULL;
            END IF;
        
            l_has_transfer := pk_transfer_institution.check_epis_transfer(l_dataset(l_row).id_episode);
        
            CASE l_has_transfer
                WHEN 0 THEN
                    l_ft_type := pk_alert_constant.g_icon_ft;
                ELSE
                    l_ft_type := pk_alert_constant.g_icon_ft_transfer;
            END CASE;
        
            l_id_fast_track := pk_fast_track.get_epis_fast_track_int(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_episode     => l_dataset(l_row).id_episode,
                                                                     i_id_epis_triage => NULL);
        
            out_obj.fast_track_icon   := pk_fast_track.get_fast_track_icon(i_lang,
                                                                           i_prof,
                                                                           l_dataset      (l_row).id_episode,
                                                                           l_id_fast_track,
                                                                           l_dataset      (l_row).id_triage_color,
                                                                           l_ft_type,
                                                                           l_has_transfer);
            out_obj.fast_track_color  := CASE l_dataset(l_row).acuity
                                             WHEN g_ft_color THEN
                                              g_ft_triage_white
                                             ELSE
                                              g_ft_color
                                         END;
            out_obj.fast_track_status := pk_alert_constant.g_ft_status;
        
            IF l_dataset(l_row).id_triage_color IS NOT NULL
            THEN
                out_obj.esi_level := pk_edis_triage.get_epis_esi_level(i_lang,
                                                                       i_prof,
                                                                       l_dataset(l_row).id_episode,
                                                                       l_dataset(l_row).id_triage_color);
            ELSE
                out_obj.esi_level := NULL;
            END IF;
        
            RESULT(l_row) := out_obj;
            --
        
            l_row := l_row + 1;
        END LOOP;
        g_error := 'RETURN DATA';
        RETURN(RESULT);
        --RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => nvl(l_error.ora_sqlerrm, SQLERRM));
            RETURN RESULT;
    END;

    --
    /**********************************************************************************************
    * Search for on-call physicians.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_sys_btn_crit        Search criteria ID's          
    * @param i_crit_val               Search criteria values
    * @param o_flg_show               Show message: (Y) yes (N) no
    * @param o_msg                    Message
    * @param o_msg_title              Message title
    * @param o_button                 Button type
    * @param o_list                   Cursor with search results
    * @param o_mess_no_result         Message to show when search doesn't return results  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Brito [Based on GET_PAT_CRITERIA_ACTIVE_ADMIN]
    * @version                        1.0 
    * @since                          2009/03/31
    **********************************************************************************************/
    FUNCTION get_on_call_physician_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where VARCHAR2(4000);
    
    BEGIN
        o_flg_show := 'N';
        g_sysdate  := SYSDATE;
        l_where    := NULL;
    
        -- Message to show when there's no results
        g_error := 'GET NO RESULTS MESSAGE';
        pk_alertlog.log_debug(g_error);
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        -- Setup WHERE condition, using given criteria and values
        g_error := 'GET WHERE CONDITION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   o_where    => l_where)
        THEN
            l_where := NULL;
        END IF;
    
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        -- Get search results
        g_error := 'GET O_LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT *
              FROM TABLE(tf_on_call_physician_criteria(i_lang, i_prof, l_where));
    
        IF g_overlimit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF g_no_results
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_list);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_ON_CALL_PHYSICIAN_CRITERIA', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_list);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_ON_CALL_PHYSICIAN_CRITERIA', o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_ON_CALL_PHYSICIAN_CRITERIA',
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_on_call_physician_criteria;

    FUNCTION tf_on_call_physician_criteria
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2
    ) RETURN t_coll_oncallphysiciancriteria IS
        l_error   t_error_out;
        c_dataset pk_types.cursor_type;
        l_limit   sys_config.value%TYPE;
    
        out_obj t_rec_oncallphysiciancriteria := t_rec_oncallphysiciancriteria(NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL,
                                                                               NULL);
    
        TYPE dataset_tt IS TABLE OF v_on_call_physician_criteria%ROWTYPE INDEX BY PLS_INTEGER;
    
        l_dataset dataset_tt;
        l_row     PLS_INTEGER := 1;
        RESULT    t_coll_oncallphysiciancriteria := t_coll_oncallphysiciancriteria();
    
        --
        l_with_notes_msg sys_message.desc_message%TYPE;
    
        l_internal_error EXCEPTION;
        l_default_period sys_config.value%TYPE;
        l_dt_start       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end         TIMESTAMP WITH LOCAL TIME ZONE;
        l_period_value   sys_domain.val%TYPE;
    BEGIN
        g_error := 'GET LIMIT';
        pk_alertlog.log_debug(g_error);
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        g_error := 'SET VARIABLES';
        pk_alertlog.log_debug(g_error);
        -- Context variables
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('g_on_call_active', pk_alert_constant.g_on_call_active);
        -- Messages
        l_with_notes_msg := '(' || pk_message.get_message(i_lang, i_prof, 'COMMON_M008') || ')';
    
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_dataset FOR 'SELECT * FROM v_on_call_physician_criteria t WHERE rownum <= :limit + 1 ' || i_where || ' '
            USING l_limit;
        --
        g_error := 'FETCH FROM RESULTS CURSOR';
        pk_alertlog.log_debug(g_error);
        FETCH c_dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        pk_alertlog.log_debug(g_error);
        CLOSE c_dataset;
        --
    
        g_error := 'COUNT RESULTS';
        pk_alertlog.log_debug(g_error);
        IF (l_dataset.count > l_limit) -- Check if number of results are over limit
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0) -- Check if number there are results
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        pk_alertlog.log_debug(g_error);
        IF (l_dataset.count < l_limit)
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        -- Start processing results    
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        pk_alertlog.log_debug(g_error);
        WHILE (l_row <= result.count)
        LOOP
            -- On-call ID
            out_obj.id_on_call_physician := l_dataset(l_row).id_on_call_physician;
        
            -- Professional info
            out_obj.id_professional := l_dataset(l_row).id_professional;
            out_obj.name            := pk_prof_utils.get_name_signature(i_lang,
                                                                        i_prof,
                                                                        l_dataset(l_row).id_professional);
            out_obj.id_speciality   := l_dataset(l_row).id_speciality;
            out_obj.desc_spec       := pk_translation.get_translation(i_lang, l_dataset(l_row).code_speciality);
        
            -- On-call info
            out_obj.title_notes     := CASE l_dataset(l_row).notes
                                           WHEN NULL THEN
                                            NULL
                                           ELSE
                                            l_with_notes_msg
                                       END;
            out_obj.dt_start        := pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_start, i_prof);
            out_obj.dt_start_extend := pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dataset(l_row).dt_start, i_prof);
            out_obj.dt_end          := pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_end, i_prof);
            out_obj.dt_end_extend   := pk_date_utils.date_hour_chr_extend_tsz(i_lang, l_dataset(l_row).dt_end, i_prof);
        
            -- Process "Status" column
            g_error := 'GET ON-CALL PERIOD DATES';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_on_call_physician.get_on_call_period_dates(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 o_default_period => l_default_period, -- Length of the period (number of days)
                                                                 o_start_date     => l_dt_start, -- On-call period start date
                                                                 o_end_date       => l_dt_end, -- On-call period end date
                                                                 o_error          => l_error)
            THEN
                RAISE l_internal_error;
            END IF;
        
            IF (l_dataset(l_row).dt_start >= l_dt_start AND l_dataset(l_row).dt_start < l_dt_end)
               OR (l_dataset(l_row).dt_start < l_dt_start AND l_dataset(l_row).dt_end > l_dt_start)
            THEN
                -- Current period
                l_period_value := pk_alert_constant.g_oncallperiod_status_c;
            
            ELSIF l_dataset(l_row).dt_start < l_dt_start
            THEN
                -- Past period
                l_period_value := pk_alert_constant.g_oncallperiod_status_p;
            
            ELSIF l_dataset(l_row).dt_start >= l_dt_end
            THEN
                -- Future period
                l_period_value := pk_alert_constant.g_oncallperiod_status_f;
            
            END IF;
        
            out_obj.period_status      := l_period_value;
            out_obj.period_status_desc := pk_sysdomain.get_domain(i_code_dom => 'ON_CALL_PHYSICIAN_PERIOD_STATUS',
                                                                  i_val      => l_period_value,
                                                                  i_lang     => i_lang);
        
            RESULT(l_row) := out_obj;
            l_row := l_row + 1;
        
        END LOOP;
    
        g_error := 'RETURN DATA';
        RETURN(RESULT);
    
    EXCEPTION
        WHEN l_internal_error THEN
            pk_alert_exceptions.raise_error(error_code_in => l_error.ora_sqlcode,
                                            text_in       => nvl(l_error.ora_sqlerrm, SQLERRM));
            RETURN RESULT;
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => nvl(l_error.ora_sqlerrm, SQLERRM));
            RETURN RESULT;
    END;

    --
    /**********************************************************************************************
    * Retornar episódios fechados de um doente na schema do ER
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_pat                    patient id
    * @param i_institution            institution id
    * @param i_software               software id   
    *
    * @return                         value
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/05/03
    **********************************************************************************************/
    FUNCTION get_prev_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN NUMBER IS
        l_prev_epis_er PLS_INTEGER := 0;
    BEGIN
        IF pk_sysconfig.get_config('ER_CLIENT_SERVER', i_institution, i_software) = 'Y'
        THEN
            g_error := 'COUNT IT';
            EXECUTE IMMEDIATE 'SELECT COUNT(0) ' || --
                              '  FROM v_outp_episodes v, pat_ext_sys pes ' || --
                              ' WHERE v.id_pat_ext = pes.VALUE ' || --
                              '   AND pes.id_patient = :i_pat ' || --
                              '   AND pes.id_external_sys = :config_val ' || --
                              '   and pes.id_institution = ' || i_institution
                INTO l_prev_epis_er
                USING i_pat, pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_institution, i_software);
        END IF;
    
        RETURN l_prev_epis_er;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;
    --
    /**********************************************************************************************
    * Contagem de pacientes por sala e por idade
    *
    * @param i_prof             professional, software and institution ids     
    * @param i_adult_child      A - Adulto; C - Criança
    * @param i_room             room id      
    *
    * @return                   value
    *
    * @author                   Teresa Coutinho
    * @version                  1.0 
    * @since                    2007/06/06
    **********************************************************************************************/
    FUNCTION get_adult_child_count
    (
        i_prof        IN profissional,
        i_adult_child IN VARCHAR2,
        i_room        IN room.id_room%TYPE
    ) RETURN NUMBER IS
        l_cont_adult_child PLS_INTEGER := 0;
        l_lim_age          sys_config.value%TYPE;
    BEGIN
        l_lim_age := pk_sysconfig.get_config('LIM_CHILD_AGE', i_prof);
        --
        IF i_adult_child = 'A'
        THEN
            g_error := 'COUNT ADULT';
            SELECT COUNT(DISTINCT id_episode)
              INTO l_cont_adult_child
              FROM v_episode_act epis, patient pat
             WHERE epis.id_patient = pat.id_patient
               AND epis.id_room = i_room
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, i_prof.institution) = i_prof.software
               AND trunc(months_between(trunc(SYSDATE), trunc(pat.dt_birth)) / 12) > l_lim_age;
        
        ELSIF i_adult_child = 'C'
        THEN
            g_error := 'COUNT CHILDERN';
            SELECT COUNT(DISTINCT id_episode)
              INTO l_cont_adult_child
              FROM v_episode_act epis, patient pat
             WHERE epis.id_patient = pat.id_patient
               AND epis.id_room = i_room
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, i_prof.institution) = i_prof.software
               AND trunc(months_between(trunc(SYSDATE), trunc(pat.dt_birth)) / 12) <= l_lim_age;
        END IF;
    
        RETURN l_cont_adult_child;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
        
    END;
    --
    /**********************************************************************************************
    * Returns search results for cancelled episodes.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        search criteria ID's      
    * @param i_crit_val               search criteria values
    * @param i_dt                     date to search
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_epis_cancel            array with cancelled episodes
    * @param o_mess_no_result         message to show when there's no results  
    * @param o_flg_show                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucessfull, FALSE otherwise
    *                        
    * @author                         José Brito [based on GET_PAT_CRITERIA_ACTIVE_ADMIN by Luís Gaspar]
    * @version                        1.0 
    * @since                          2008/04/22
    **********************************************************************************************/
    FUNCTION get_epis_cancelled
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_cancel     OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where VARCHAR2(4000);
        l_from  VARCHAR2(32767);
        l_hint  VARCHAR2(32767);
        l_limit sys_config.desc_sys_config%TYPE;
        l_date  VARCHAR2(40);
    
        l_prof_cat     category.flg_type%TYPE;
        l_sysdate_char VARCHAR2(32);
    
    BEGIN
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show     := 'N';
        g_sysdate_tstz := SYSDATE;
        --
        l_limit    := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        --o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        --
        l_where := NULL;
        l_date  := to_char(trunc(nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL), current_timestamp)),
                           'YYYYMMDD');
        --
        g_error := 'GET WHERE';
        IF (NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                    i_crit_val => i_crit_val,
                                    i_lang     => i_lang,
                                    i_prof     => i_prof,
                                    o_where    => l_where))
        THEN
            l_where := NULL;
        END IF;
        --
        g_error := 'GET FROM';
        IF (NOT pk_search.get_from(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   o_from     => l_from,
                                   o_hint     => l_hint))
        THEN
            l_from := NULL;
        END IF;
        --
    
        -- 1º select vai sobre os episódios de urgência
        -- 2º select vai sobre os episódios de OBS
        g_error      := 'OPEN O_EPIS_CANCEL';
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        --
        OPEN o_epis_cancel FOR --
            SELECT *
              FROM TABLE(tf_epis_cancelled(i_lang, i_prof, l_where, l_from, l_hint));
    
        g_error := 'TEST NUMBER OF RESULTS';
        IF g_overlimit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF g_no_results
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_epis_cancel);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_EPIS_CANCELLED', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_epis_cancel);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_EPIS_CANCELLED', o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_cancel);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_PROC',
                                              'GET_EPIS_CANCELLED',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION tf_epis_cancelled
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_episcancelled IS
        l_error        t_error_out;
        dataset        pk_types.cursor_type;
        l_limit        sys_config.desc_sys_config%TYPE;
        l_sysdate_char VARCHAR2(32);
        out_obj        t_rec_episcancelled := t_rec_episcancelled(origem                   => NULL,
                                                                  acuity                   => NULL,
                                                                  color_text               => NULL,
                                                                  rank_acuity              => NULL,
                                                                  id_episode               => NULL,
                                                                  id_patient               => NULL,
                                                                  dt_server                => NULL,
                                                                  pat_age                  => NULL,
                                                                  gender                   => NULL,
                                                                  photo                    => NULL,
                                                                  name_pat                 => NULL,
                                                                  name_pat_sort            => NULL,
                                                                  pat_ndo                  => NULL,
                                                                  pat_nd_icon              => NULL,
                                                                  num_clin_record          => NULL,
                                                                  attaches                 => NULL,
                                                                  transfer_req_time        => NULL,
                                                                  dt_begin                 => NULL,
                                                                  inp_admission_time       => NULL,
                                                                  disch_pend_time          => NULL,
                                                                  disch_time               => NULL,
                                                                  dt_follow_up_date        => NULL,
                                                                  label_follow_up_date     => NULL,
                                                                  hour_mask_follow_up_date => NULL,
                                                                  date_mask_follow_up_date => NULL,
                                                                  rank                     => NULL,
                                                                  flg_status               => NULL,
                                                                  pat_age_for_order_by     => NULL,
                                                                  fast_track_icon          => NULL,
                                                                  fast_track_color         => NULL,
                                                                  fast_track_status        => NULL,
                                                                  esi_level                => NULL);
    
        CURSOR l_cur IS
            SELECT 1 position, g_no_triage_color_id id_triage_color, t.*
              FROM v_src_edis_cancelled t;
    
        TYPE dataset_tt IS TABLE OF l_cur%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset              dataset_tt;
        l_row                  PLS_INTEGER := 1;
        RESULT                 t_coll_episcancelled := t_coll_episcancelled();
        l_task_arrival         TIMESTAMP WITH LOCAL TIME ZONE;
        l_test1                VARCHAR2(1);
        l_test2                TIMESTAMP WITH LOCAL TIME ZONE;
        l_test3                TIMESTAMP WITH LOCAL TIME ZONE;
        l_msg_edis_grid_t054   sys_message.desc_message%TYPE;
        l_msg_edis_common_t002 sys_message.desc_message%TYPE;
        l_msg_edis_common_t003 sys_message.desc_message%TYPE;
        l_msg_edis_common_t004 sys_message.desc_message%TYPE;
        l_screens              table_varchar := table_varchar('ADMIN_DISCHARGE', 'PATIENT_ARRIVAL');
        l_has_transfer         NUMBER(6);
        l_ft_type              fast_track.icon%TYPE;
        l_id_fast_track        fast_track.id_fast_track%TYPE;
    
        l_query VARCHAR2(32767);
    
        l_query_triage_color CONSTANT VARCHAR2(4000) := 'nvl((SELECT id_triage_color
                                                                FROM (SELECT etr.id_triage_color, etr.id_episode
                                                                        FROM epis_triage etr
                                                                       ORDER BY etr.dt_end_tstz DESC) et
                                                               WHERE et.id_episode = t.id_episode
                                                                 AND rownum < 2),
                                                             sys_context(''ALERT_CONTEXT'', ''g_no_triage_color_id'')) id_triage_color, ';
    BEGIN
        --
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
    
        pk_context_api.set_parameter('g_sysdate_tstz', g_sysdate_tstz);
        pk_context_api.set_parameter('g_cancelled', g_cancelled);
        pk_context_api.set_parameter('g_no_triage_color_id', g_no_triage_color_id);
        pk_context_api.set_parameter('g_discharge_flg_status_active', g_discharge_flg_status_active);
        pk_context_api.set_parameter('g_discharge_flg_status_pend', g_discharge_flg_status_pend);
        pk_context_api.set_parameter('g_episode_flg_type_temp', g_episode_flg_type_temp);
        pk_context_api.set_parameter('g_episode_flg_type_def', g_episode_flg_type_def);
        pk_context_api.set_parameter('g_epis_type_urg', g_epis_type_urg);
        pk_context_api.set_parameter('g_no_color_rank', g_no_color_rank);
        pk_context_api.set_parameter('g_no_triage', g_no_triage);
        pk_context_api.set_parameter('g_no_triage_color_text', g_no_triage_color_text);
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
        --
        g_error := 'CALL PK_ACCESS.PRELOAD_SHORTCUTS';
        IF NOT
            pk_access.preload_shortcuts(i_lang => i_lang, i_prof => i_prof, i_screens => l_screens, o_error => l_error)
        THEN
            RETURN RESULT;
        END IF;
        --
        l_query := 'SELECT ' || nvl(i_hint, 'NULL position, ') || l_query_triage_color || 't.* ' || --
                   ' FROM v_src_edis_cancelled t ' || i_from || --
                   ' WHERE rownum <= :limit + 1 ' || i_where || ' ' || ' ORDER BY dt_rank, name_pat';
        --
        g_error := 'OPEN DATASET';
        OPEN dataset FOR l_query
            USING l_limit;
        --
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
        --
        l_msg_edis_grid_t054   := pk_message.get_message(i_lang, 'EDIS_GRID_T054');
        l_msg_edis_common_t002 := pk_message.get_message(i_lang, 'EDIS_COMMON_T002');
        l_msg_edis_common_t003 := pk_message.get_message(i_lang, 'EDIS_COMMON_T003');
        l_msg_edis_common_t004 := pk_message.get_message(i_lang, 'EDIS_COMMON_T004');
    
        g_error := 'COUNT RESULTS';
        IF (l_dataset.count > l_limit)
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0)
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF (l_dataset.count < l_limit)
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        --
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        WHILE (l_row <= result.count)
        LOOP
            IF (l_dataset(l_row).query = 1)
            THEN
                l_task_arrival := pk_transfer_institution.get_grid_task_arrival(i_lang,
                                                                                i_prof,
                                                                                l_dataset(l_row).id_episode);
                IF (l_task_arrival IS NULL)
                THEN
                    l_test1 := pk_ubu.get_episode_transportation(l_dataset(l_row).id_episode, i_prof);
                ELSE
                    l_test1 := 'N';
                END IF;
            
                IF (l_test1 IS NULL)
                THEN
                    IF (i_prof.software = g_soft_edis)
                    THEN
                        out_obj.origem := l_msg_edis_common_t002;
                    ELSE
                        out_obj.origem := l_msg_edis_common_t004;
                    END IF;
                ELSE
                    out_obj.origem := l_msg_edis_common_t004;
                END IF;
            
                IF (l_dataset(l_row).flg_status_d IS NULL)
                THEN
                    IF (l_test1 = 'T')
                    THEN
                        l_test2 := l_task_arrival;
                    ELSE
                        IF (l_test1 = 'Y')
                        THEN
                            l_test2 := pk_ubu.get_date_transportation(l_dataset(l_row).id_episode);
                        ELSIF (l_test1 = 'N')
                        THEN
                            l_test2 := NULL;
                        ELSE
                            IF l_dataset(l_row).dt_first_obs_tstz IS NULL
                            THEN
                                l_test2 := l_dataset(l_row).dt_begin_tstz;
                            ELSE
                                l_test2 := NULL;
                            END IF;
                        END IF;
                    END IF;
                
                ELSE
                    IF (l_dataset(l_row).flg_status_d = g_discharge_flg_status_reopen)
                    THEN
                        IF (l_dataset(l_row).dt_first_obs_tstz IS NULL)
                        THEN
                            l_test2 := CASE l_test1
                                           WHEN 'T' THEN
                                            l_task_arrival
                                           WHEN 'Y' THEN
                                            pk_ubu.get_date_transportation(l_dataset(l_row).id_episode)
                                           WHEN 'N' THEN
                                            NULL
                                           ELSE
                                            l_dataset(l_row).dt_begin_tstz
                                       END;
                        END IF;
                    END IF;
                END IF;
            
                out_obj.dt_begin           := pk_date_utils.date_send_tsz(i_lang, l_test2, i_prof);
                l_test3                    := CASE l_dataset(l_row).flg_type_epis_obs
                                                  WHEN g_episode_flg_type_temp THEN
                                                   pk_date_utils.add_to_ltstz(l_dataset(l_row).dt_begin_tstz_obs, 1)
                                              END;
                out_obj.inp_admission_time := pk_date_utils.date_send_tsz(i_lang, l_test3, i_prof);
            
                out_obj.disch_pend_time := NULL;
                --out_obj.disch_pend_time := CASE l_dataset(l_row).flg_status_d WHEN g_discharge_flg_status_pend THEN pk_date_utils.date_send_tsz(i_lang, nvl(l_dataset(l_row).dt_med_tstz, l_dataset(l_row).dt_pend_tstz), i_prof) END;
                out_obj.disch_time := NULL;
                --out_obj.disch_time := CASE l_dataset(l_row).flg_status_epis WHEN g_epis_pending THEN(CASE l_dataset(l_row).flg_type_epis_obs WHEN g_episode_flg_type_temp THEN NULL ELSE pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_med_tstz, i_prof) END) END;
            
                out_obj.rank := pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_rank, i_prof);
            ELSE
                IF (l_dataset(l_row).query = 2)
                THEN
                    out_obj.origem             := CASE l_dataset(l_row).flg_type
                                                      WHEN g_episode_flg_type_def THEN
                                                       l_msg_edis_common_t003
                                                      ELSE
                                                       l_msg_edis_common_t002
                                                  END;
                    out_obj.dt_begin := pk_date_utils.date_send_tsz(i_lang,
                                                                    CASE
                                                                        WHEN l_dataset(l_row).dt_first_obs_tstz IS NULL THEN
                                                                         l_dataset(l_row).dt_begin_tstz
                                                                        ELSE
                                                                         to_timestamp(NULL)
                                                                    END,
                                                                    i_prof);
                    out_obj.inp_admission_time := NULL;
                    out_obj.disch_pend_time    := NULL;
                    --out_obj.disch_pend_time    := CASE l_dataset(l_row).flg_status_d WHEN g_discharge_flg_status_pend THEN pk_date_utils.date_send_tsz(i_lang, nvl(l_dataset(l_row).dt_med_tstz, l_dataset(l_row).dt_pend_tstz), i_prof) ELSE NULL END;
                    out_obj.disch_time := NULL;
                    --out_obj.disch_time         := pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_med_tstz, i_prof);
                    out_obj.rank := pk_date_utils.date_send_tsz(i_lang,
                                                                CASE l_dataset(l_row).flg_status_epis
                                                                    WHEN g_epis_pending THEN
                                                                     l_dataset(l_row).dt_med_tstz
                                                                    ELSE
                                                                     CASE
                                                                         WHEN l_dataset(l_row).dt_first_obs_tstz IS NULL THEN
                                                                          l_dataset(l_row).dt_begin_tstz
                                                                     END
                                                                END,
                                                                i_prof);
                END IF;
            END IF;
        
            out_obj.acuity          := l_dataset(l_row).acuity;
            out_obj.color_text      := l_dataset(l_row).color_text;
            out_obj.rank_acuity     := l_dataset(l_row).rank_acuity;
            out_obj.id_episode      := l_dataset(l_row).id_episode;
            out_obj.id_patient      := l_dataset(l_row).id_patient;
            out_obj.dt_server       := l_sysdate_char;
            out_obj.name_pat        := l_dataset(l_row).name_pat;
            out_obj.name_pat_sort   := l_dataset(l_row).name_pat_sort;
            out_obj.pat_ndo         := l_dataset(l_row).pat_ndo;
            out_obj.pat_nd_icon     := l_dataset(l_row).pat_nd_icon;
            out_obj.num_clin_record := l_dataset(l_row).num_clin_record;
            out_obj.flg_status      := l_dataset(l_row).flg_status_epis;
        
            out_obj.pat_age              := pk_patient.get_pat_age(i_lang,
                                                                   l_dataset         (l_row).dt_birth,
                                                                   l_dataset         (l_row).dt_deceased,
                                                                   l_dataset         (l_row).age,
                                                                   i_prof.institution,
                                                                   i_prof.software);
            out_obj.pat_age_for_order_by := pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                                       i_prof    => i_prof,
                                                                                       i_type    => pk_edis_proc.g_sort_type_age,
                                                                                       i_episode => l_dataset(l_row).id_episode);
            out_obj.gender               := pk_patient.get_gender(i_lang, l_dataset(l_row).gender);
            out_obj.photo                := pk_patphoto.get_pat_photo(i_lang,
                                                                      i_prof,
                                                                      l_dataset(l_row).id_patient,
                                                                      l_dataset(l_row).id_episode,
                                                                      NULL);
            out_obj.attaches             := pk_doc.get_num_episode_images(l_dataset(l_row).id_episode,
                                                                          l_dataset(l_row).id_patient);
        
            out_obj.transfer_req_time := nvl(pk_transfer_institution.get_grid_task_departure(i_lang,
                                                                                             i_prof,
                                                                                             l_dataset(l_row).id_episode),
                                             CASE l_test1
                                                 WHEN 'N' THEN
                                                  pk_access.get_shortcut('PATIENT_ARRIVAL') || '|' ||
                                                  pk_date_utils.date_send_tsz(i_lang,
                                                                              l_dataset(l_row).dt_begin_tstz,
                                                                              i_prof) || '|' || 'R' || '|' || 'X'
                                                 ELSE
                                                  NULL
                                             END);
        
            out_obj.dt_follow_up_date        := NULL;
            out_obj.label_follow_up_date     := NULL;
            out_obj.hour_mask_follow_up_date := NULL;
            out_obj.date_mask_follow_up_date := NULL;
        
            l_has_transfer := pk_transfer_institution.check_epis_transfer(l_dataset(l_row).id_episode);
        
            CASE l_has_transfer
                WHEN 0 THEN
                    l_ft_type := pk_alert_constant.g_icon_ft;
                ELSE
                    l_ft_type := pk_alert_constant.g_icon_ft_transfer;
            END CASE;
        
            l_id_fast_track := pk_fast_track.get_epis_fast_track_int(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_id_episode     => l_dataset(l_row).id_episode,
                                                                     i_id_epis_triage => NULL);
        
            out_obj.fast_track_icon   := pk_fast_track.get_fast_track_icon(i_lang,
                                                                           i_prof,
                                                                           l_dataset      (l_row).id_episode,
                                                                           l_id_fast_track,
                                                                           l_dataset      (l_row).id_triage_color,
                                                                           l_ft_type,
                                                                           l_has_transfer);
            out_obj.fast_track_color  := CASE l_dataset(l_row).acuity
                                             WHEN pk_alert_constant.g_ft_color THEN
                                              pk_alert_constant.g_ft_triage_white
                                             ELSE
                                              pk_alert_constant.g_ft_color
                                         END;
            out_obj.fast_track_status := pk_alert_constant.g_ft_status;
        
            IF l_dataset(l_row).id_triage_color IS NOT NULL
            THEN
                out_obj.esi_level := pk_edis_triage.get_epis_esi_level(i_lang,
                                                                       i_prof,
                                                                       l_dataset(l_row).id_episode,
                                                                       l_dataset(l_row).id_triage_color);
            ELSE
                out_obj.esi_level := NULL;
            END IF;
        
            RESULT(l_row) := out_obj;
            --
        
            l_row := l_row + 1;
        END LOOP;
        g_error := 'RETURN DATA';
        RETURN(RESULT);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => nvl(l_error.ora_sqlerrm, SQLERRM));
            RETURN RESULT;
    END;

    --
    /********************************************************************************************
    * Checks if the professional can access the reopen functionality
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_episode               episode id
    * @param i_epis_software         episode software 
    *
    * @return                        flg_reopen: Y - can access reopen popup ; N - can't access reopen popup
    *
    * @author                        José Silva
    * @version                       1.0    
    * @since                         24-04-2008
    ********************************************************************************************/
    FUNCTION check_flg_reopen
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_software IN epis_type_soft_inst.id_software%TYPE
    ) RETURN VARCHAR2 IS
    
        l_prof_software   software.id_software%TYPE;
        l_vis_institution institution.id_institution%TYPE;
    
        CURSOR c_epis_reopen IS
            SELECT 0
              FROM episode e, epis_info ei
             WHERE ei.id_episode = e.id_episode
               AND e.id_episode = i_episode
                  -- José Brito 17/07/2008 Correcção necessária para que o administrativo do Inpatient não possa reabrir episódios OBS
               AND i_epis_software =
                   decode((SELECT pk_inp_episode.check_obs_episode(i_lang, i_prof, e.id_episode)
                            FROM dual),
                          0,
                          l_prof_software,
                          decode(l_prof_software,
                                 g_soft_edis,
                                 decode(pk_prof_utils.get_category(i_lang, i_prof), g_prof_cat_administrative, g_soft_inp),
                                 g_soft_inp,
                                 decode(pk_prof_utils.get_category(i_lang, i_prof),
                                        g_prof_cat_administrative,
                                        NULL,
                                        g_soft_inp),
                                 NULL));
    
        l_num NUMBER;
    
    BEGIN
    
        IF i_prof.software = g_soft_triage
        THEN
            l_prof_software := pk_episode.get_soft_by_epis_type(pk_sysconfig.get_config('EPIS_TYPE', i_prof),
                                                                i_prof.institution);
        ELSE
            l_prof_software := i_prof.software;
        END IF;
    
        OPEN c_epis_reopen;
        FETCH c_epis_reopen
            INTO l_num;
    
        IF c_epis_reopen%NOTFOUND
           AND i_prof.software <> g_soft_pharm
        THEN
            RETURN g_no;
        ELSE
            BEGIN
                SELECT v.id_institution
                  INTO l_vis_institution
                  FROM visit v
                  JOIN episode e
                    ON e.id_visit = v.id_visit
                 WHERE e.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_vis_institution := NULL;
            END;
        
            IF l_vis_institution = i_prof.institution
            THEN
                RETURN g_yes;
            ELSE
                RETURN g_no;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN g_no;
    END check_flg_reopen;

    /********************************************************************************************
    * Changes the episode id_dep_clin_serv 
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_episode               episode id
    * @param i_dep_clin_serv         id_dep_clin_serv
    *
    * @return                        TRUE/ FALSE
    *
    * @author                        Elisabete Bugalho
    * @version                       1.0    
    * @since                        11-10-2012
    ********************************************************************************************/
    FUNCTION set_epis_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_department     department.id_department%TYPE;
        l_id_dept           dept.id_dept%TYPE;
        l_id_cs             clinical_service.id_clinical_service%TYPE;
        l_rowids            table_varchar;
        l_epis_doc_template table_number;
        l_epis_type         episode.id_epis_type%TYPE;
    BEGIN
        SELECT dcs.id_clinical_service, d.id_department, d.id_dept
          INTO l_id_cs, l_id_department, l_id_dept
          FROM dep_clin_serv dcs, department d
         WHERE dcs.id_dep_clin_serv = i_dep_clin_serv
           AND dcs.id_department = d.id_department;
    
        g_error := 'CALL pk_episode.get_epis_type. i_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_epis_type := pk_episode.get_epis_type(i_lang => i_lang, i_id_epis => i_episode);
    
        g_error := 'INSERT INTO EPISODE';
        ts_episode.upd(id_episode_in          => i_episode,
                       id_clinical_service_in => nvl(l_id_cs, -1),
                       id_department_in       => nvl(l_id_department, -1),
                       id_dept_in             => nvl(l_id_dept, -1),
                       rows_out               => l_rowids);
    
        g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE EPISODE';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPISODE',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_CLINICAL_SERVICE', 'ID_DEPARTMENT', 'ID_DEPT'));
    
        l_rowids := table_varchar();
        g_error  := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_episode_in => i_episode,
                         
                         id_dep_clin_serv_in       => i_dep_clin_serv,
                         id_first_dep_clin_serv_in => i_dep_clin_serv,
                         
                         rows_out => l_rowids);
    
        g_error := 'T_DATA_GOV_MNT.PROCESS_UPDATE EPIS_INFO';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INFO',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_DEP_CLIN_SERV', 'ID_FIRST_DEP_CLIN_SERV'));
    
        --  update epis_doc_template for (new) clinical_service                              
        g_error := ' pk_touch_option.set_default_epis_doc_templates';
        IF NOT pk_touch_option.set_default_epis_doc_templates(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_episode            => i_episode,
                                                         i_flg_type           => CASE
                                                                                     WHEN l_epis_type =
                                                                                          pk_alert_constant.g_epis_type_inpatient THEN
                                                                                      g_flg_type_specialty
                                                                                     ELSE
                                                                                      g_flg_type_appointment_type
                                                                                 END,
                                                         o_epis_doc_templates => l_epis_doc_template,
                                                         o_error              => o_error)
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
                                              'PK_EDIS_PROC',
                                              'SET_EPIS_CLIN_SERV',
                                              o_error);
            RETURN FALSE;
        
    END;

    PROCEDURE get_los_dates
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN movement.dt_end_tstz%TYPE DEFAULT NULL,
        i_dt_end     IN episode.dt_end_tstz%TYPE DEFAULT NULL,
        o_dt_begin   OUT movement.dt_end_tstz%TYPE,
        o_dt_end     OUT episode.dt_end_tstz%TYPE
    ) IS
        l_func_name             VARCHAR2(30 CHAR) := 'GET_LOS_DURATION';
        l_check_intake_time_cfg sys_config.desc_sys_config%TYPE;
        l_date_begin            epis_intake_time.dt_register%TYPE;
        l_date_end              epis_intake_time.dt_register%TYPE;
        l_date_discharge        discharge.dt_admin_tstz%TYPE;
        l_error                 t_error_out;
    BEGIN
        -- calculate begin date
        IF i_dt_begin IS NOT NULL
        THEN
            o_dt_begin := i_dt_begin;
        ELSE
            l_check_intake_time_cfg := pk_sysconfig.get_config('USE_INTAKE_TIME_TO_CALCULATE_LOS', i_prof);
            IF l_check_intake_time_cfg = g_yes
            THEN
                BEGIN
                    SELECT dt_intake_time
                      INTO l_date_begin
                      FROM (SELECT eit.dt_intake_time
                              FROM epis_intake_time eit
                             WHERE eit.id_episode = i_id_episode
                             ORDER BY eit.dt_register DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            IF l_check_intake_time_cfg = g_no
               OR l_date_begin IS NULL
            THEN
                SELECT e.dt_begin_tstz
                  INTO l_date_begin
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            END IF;
        
            o_dt_begin := l_date_begin;
        END IF;
    
        -- calculate end date
        IF i_dt_end IS NOT NULL
        THEN
            o_dt_end := i_dt_end;
        ELSE
            -- check discharge date
            SELECT MAX(d.dt_admin_tstz)
              INTO l_date_discharge
              FROM discharge d
             WHERE d.id_episode = i_id_episode
               AND d.id_prof_admin IS NOT NULL
               AND d.flg_status = pk_alert_constant.g_active;
        
            SELECT nvl(l_date_discharge, current_timestamp)
              INTO l_date_end
              FROM dual;
        
            o_dt_end := l_date_end;
        END IF;
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
    END get_los_dates;

    /********************************************************************************************
    * Calculates length of stay of the patient
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_id_episode            episode id
    * @param i_dt_begin              Optional begin date (used in lenght of stay in a room)
    * @param i_dt_end                Optional end date (used in lenght of stay in a room)
    * @param i_flg_sort              Optional flag that decides what is returned. Y - numeric value for sorting; N (default) - string value for display in grids
    *
    * @return                        TRUE/ FALSE
    *
    * @author                        Sergio Dias
    * @version                       2.6.3.7.1
    * @since                         11-10-2012
    ********************************************************************************************/
    FUNCTION get_los_duration
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN movement.dt_end_tstz%TYPE DEFAULT NULL,
        i_dt_end     IN episode.dt_end_tstz%TYPE DEFAULT NULL,
        i_flg_sort   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_func_name      VARCHAR2(30 CHAR) := 'GET_LOS_DURATION';
        l_result         VARCHAR2(50 CHAR);
        l_date_begin     epis_intake_time.dt_register%TYPE;
        l_date_end       epis_intake_time.dt_register%TYPE;
        l_error          t_error_out;
        l_decimal_symbol sys_config.value%TYPE := pk_sysconfig.get_config('DECIMAL_SYMBOL', i_prof);
    BEGIN
        -- calculate begin date
        get_los_dates(i_lang       => i_lang,
                      i_prof       => i_prof,
                      i_id_episode => i_id_episode,
                      i_dt_begin   => i_dt_begin,
                      i_dt_end     => i_dt_end,
                      o_dt_begin   => l_date_begin,
                      o_dt_end     => l_date_end);
    
        -- calculate final value
        IF i_flg_sort = pk_alert_constant.g_yes
        THEN
            l_result := to_char(abs(pk_date_utils.get_timestamp_diff(l_date_begin, l_date_end)),
                                '99990' || l_decimal_symbol || '9999');
        ELSE
            l_result := pk_date_utils.get_elapsed_tsz(i_lang, l_date_begin, l_date_end);
        END IF;
    
        RETURN l_result;
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
            RETURN l_result;
        
    END get_los_duration;
    /********************************************************************************************
    * Calculates length of stay of the patient
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_id_episode            episode id
    * @param i_dt_begin              Optional begin date (used in lenght of stay in a room)
    * @param i_dt_end                Optional end date (used in lenght of stay in a room)
    * @param i_flg_sort              Optional flag that decides what is returned. Y - numeric value for sorting; N (default) - string value for display in grids
    *
    * @return                        TRUE/ FALSE
    *
    * @author                        Sergio Dias
    * @version                       2.6.3.7.1
    * @since                         11-10-2012
    ********************************************************************************************/
    FUNCTION get_los_duration_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN movement.dt_end_tstz%TYPE DEFAULT NULL,
        i_dt_end     IN episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN NUMBER IS
        l_func_name  VARCHAR2(30 CHAR) := 'GET_LOS_DURATION';
        l_result     NUMBER;
        l_date_begin epis_intake_time.dt_register%TYPE;
        l_date_end   epis_intake_time.dt_register%TYPE;
        l_error      t_error_out;
    BEGIN
        -- calculate begin date
        get_los_dates(i_lang       => i_lang,
                      i_prof       => i_prof,
                      i_id_episode => i_id_episode,
                      i_dt_begin   => i_dt_begin,
                      i_dt_end     => i_dt_end,
                      o_dt_begin   => l_date_begin,
                      o_dt_end     => l_date_end);
    
        l_result := abs(pk_date_utils.get_timestamp_diff(l_date_begin, l_date_end));
    
        RETURN l_result;
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
            RETURN l_result;
        
    END get_los_duration_number;
    /********************************************************************************************
    * Calculates string to sort grids (LOS and patient age)
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_type                  Type of call: A - patient age call, L - LOS call
    * @param i_id_episode            Episode id
    *
    * @return                        concattenated string
    *
    * @author                        Sergio Dias
    * @version                       2.6.4.2
    * @since                         19-9-2014
    ********************************************************************************************/
    FUNCTION get_formatted_string_for_sort
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_type    IN VARCHAR2,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_FORMATTED_STRING_FOR_SORT';
        l_error     t_error_out;
        l_result    VARCHAR2(120 CHAR);
    
        l_years_string   VARCHAR2(3 CHAR);
        l_months_string  VARCHAR2(2 CHAR);
        l_days_string    VARCHAR2(4 CHAR);
        l_hours_string   VARCHAR2(2 CHAR);
        l_minutes_string VARCHAR2(2 CHAR);
    
        l_type_age           CONSTANT VARCHAR2(1 CHAR) := 'A';
        l_empty_section      CONSTANT VARCHAR2(2 CHAR) := '00';
        l_empty_year_section CONSTANT VARCHAR2(4 CHAR) := '000';
        l_empty_days_section CONSTANT VARCHAR2(4 CHAR) := '0000';
    
        l_date_begin episode.dt_begin_tstz%TYPE;
        l_date_end   episode.dt_end_tstz%TYPE;
    
        l_months_aux NUMBER;
        l_num_age    NUMBER;
        l_age        patient.age%TYPE;
        l_dt_birth   patient.dt_birth%TYPE;
    
        PROCEDURE get_date_values
        (
            p_dt_begin IN episode.dt_begin_tstz%TYPE DEFAULT NULL,
            p_dt_end   IN episode.dt_end_tstz%TYPE DEFAULT NULL
        ) IS
            l_years   NUMBER;
            l_months  NUMBER;
            l_days    NUMBER;
            l_hours   NUMBER;
            l_minutes NUMBER;
            l_seconds NUMBER;
        BEGIN
            IF NOT pk_date_utils.get_timestamp_diff_sep(i_lang        => i_lang,
                                                        i_timestamp_1 => p_dt_begin,
                                                        i_timestamp_2 => nvl(p_dt_end, current_timestamp),
                                                        o_years       => l_years,
                                                        o_months      => l_months,
                                                        o_error       => l_error)
            THEN
                NULL;
            END IF;
        
            IF NOT pk_date_utils.get_timestamp_diff_sep(i_lang        => i_lang,
                                                        i_timestamp_1 => p_dt_begin,
                                                        i_timestamp_2 => nvl(p_dt_end, current_timestamp),
                                                        o_days        => l_days,
                                                        o_hours       => l_hours,
                                                        o_minutes     => l_minutes,
                                                        o_seconds     => l_seconds,
                                                        o_error       => l_error)
            THEN
                NULL;
            END IF;
            l_years_string   := lpad(str1 => abs(l_years), len => 3, pad => '0');
            l_months_string  := lpad(str1 => abs(l_months), len => 2, pad => '0');
            l_days_string    := lpad(str1 => abs(l_days), len => 4, pad => '0');
            l_hours_string   := lpad(str1 => abs(l_hours), len => 2, pad => '0');
            l_minutes_string := lpad(str1 => abs(l_minutes), len => 2, pad => '0');
        END;
    
    BEGIN
        IF i_type = l_type_age
        THEN
            SELECT p.age, p.dt_birth
              INTO l_age, l_dt_birth
              FROM episode e
              LEFT JOIN patient p
                ON e.id_patient = p.id_patient
             WHERE e.id_episode = i_episode;
        
            l_months_aux := pk_patient.get_pat_age(i_lang       => i_lang,
                                                   i_dt_birth   => l_dt_birth,
                                                   i_age        => l_age,
                                                   i_age_format => 'MONTHS');
        
            IF l_months_aux < 1
            THEN
                l_num_age := pk_patient.get_pat_age(i_lang       => i_lang,
                                                    i_dt_birth   => l_dt_birth,
                                                    i_age        => l_age,
                                                    i_age_format => 'DAYS');
            
                l_days_string := l_num_age;
            
            ELSIF l_months_aux > 36
            THEN
                l_num_age := pk_patient.get_pat_age(i_lang       => i_lang,
                                                    i_dt_birth   => l_dt_birth,
                                                    i_age        => l_age,
                                                    i_age_format => 'YEARS');
            
                l_years_string := lpad(str1 => l_num_age, len => 3, pad => '0');
            ELSE
                l_months_string := l_months_aux;
            END IF;
        ELSE
            -- if the episode was passed and the dt_begin was not, this is a LOS field, calculates the dates
            get_los_dates(i_lang       => i_lang,
                          i_prof       => i_prof,
                          i_id_episode => i_episode,
                          o_dt_begin   => l_date_begin,
                          o_dt_end     => l_date_end);
        
            get_date_values(p_dt_begin => l_date_begin, p_dt_end => l_date_end);
        END IF;
    
        IF to_number(l_years_string) > 0
           AND i_type = l_type_age
        THEN
            l_result := l_years_string || l_empty_section || l_empty_days_section || l_empty_section || l_empty_section;
        ELSE
            IF to_number(l_months_string) > 0
               AND i_type = l_type_age
            THEN
                l_result := l_empty_year_section || l_months_string || l_empty_days_section || l_empty_section ||
                            l_empty_section;
            ELSE
                IF to_number(l_days_string) > 0
                THEN
                    l_result := l_empty_year_section || l_empty_section || l_days_string || l_empty_section ||
                                l_empty_section;
                ELSE
                    IF (to_number(l_hours_string) > 0 OR to_number(l_minutes_string) > 0)
                    THEN
                        l_result := l_empty_year_section || l_empty_section || l_empty_days_section || l_hours_string ||
                                    l_minutes_string;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_result;
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
            RETURN SQLERRM;
    END get_formatted_string_for_sort;

END pk_edis_proc;
/
