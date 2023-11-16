/*-- Last Change Revision: $Rev: 2027239 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:36 +0100 (ter, 02 ago 2022) $*/


CREATE OR REPLACE PACKAGE BODY pk_information IS

    /********************************************************************************************
    * Retornar os dados para o cabeçalho da aplicação 
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_ID_PAT            ID do doente 
    * @param      I_ID_EPISODE        ID do episódio
    * @param      O_NAME              nome completo 
    * @param      O_GENDER            sexo do doente 
    * @param      O_AGE               idade do doente 
    * @param      O_HEALTH_PLAN       subsistema de saúde do utente
    * @param      O_COMPL_PAIN        Queixa completa 
    * @param      O_INFO_ADIC         Informação adicional (descrição da categoria + data da última alteração +nome do profissional)
    * @param      O_CAT_PROF          Categoria do profissional  
    * @param      O_CAT_NURSE         Categoria da enfermeira
    * @param      O_COMPL_DIAG        Diagnósticos
    * @param      O_PROF_NAME         nome do médico da consulta 
    * @param      O_NURSE_NAME        Nome da enfermeira
    * @param      O_PROF_SPEC         especialidade do médico da urgência
    * @param      O_NURSE_SPEC        especialidade da enfermeira da urgência
    * @param      O_ACUITY            Acuidade
    * @param      O_EPISODE           nº episódio no sistema externo e título
    * @param      O_CLIN_REC          nº do processo clínico na instituição onde se está a aceder à aplicação (SYS_CONFIG) e título
    * @param      O_LOCATION          localização e título 
    * @param      O_TIME_ROOM         tempo na sala 
    * @param      O_ADMIT             tempo de admissão e título
    * @param      O_TOTAL_TIME        tempo total
    * @param      O_PAT_PHOTO         URL da directoria da foto do doente
    * @param      O_PROF_PHOTO        URL da directoria da foto do profissional
    * @param      O_HABIT             nº de hábitos
    * @param      O_ALLERGY           nº de alergias 
    * @param      O_PREV_EPIS         nº de episódios anteriores 
    * @param      O_RELEV_DISEASE     nº de doenças relevantes 
    * @param      O_BLOOD_TYPE        tipo sanguíneo 
    * @param      O_RELEV_NOTE        notas relevantes 
    * @param      O_APPLICATION       área aplicacional
    * @param      O_INFO              
    * @param      O_ERROR             erro
    
    * @return     boolean
    
    * @author     SS
    * @version    0.1
    * @since      2007/04/27
    **********************************************************************************************/

    FUNCTION get_clinical_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_clinical_service IS
            SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type
              FROM episode e
              JOIN clinical_service cs
                ON e.id_clinical_service = cs.id_clinical_service
             WHERE e.id_episode = i_episode;
    
        rec_get_clinical_service c_get_clinical_service%ROWTYPE;
    
    BEGIN
        OPEN c_get_clinical_service;
        FETCH c_get_clinical_service
            INTO rec_get_clinical_service;
        CLOSE c_get_clinical_service;
    
        RETURN rec_get_clinical_service.cons_type;
    
    END get_clinical_service;

    /********************************************************************************************
    * Obter a descrição da categoria do profissional  
    *
    * @param      I_LANG              Língua registada como preferência do profissional
    * @param      I_PROF              ID do profissional 
    * @param      O_CAT_PROF          descrição da categoria
    * @param      O_FLG_TYPE              Tipo de categoria
    * @param      O_ERROR             erro
    *
    * @return     boolean
    
    * @author     SS
    * @version    0.1
    * @since      2007/01/04
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
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_INFORMATION',
                                                     'GET_CATEGORY_PROF',
                                                     o_error);
    END get_category_prof;

    /********************************************************************************************
     * Information desk grid for active episodes: shows no registered episodes and registered episodes without administrative discharge
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_active            Active episodes 
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     CRS
     * @version    0.1
     * @since      2005/04/07 
    **********************************************************************************************/
    FUNCTION information_active
    (
        i_lang      IN language.id_language%TYPE,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_active    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode episode.id_episode%TYPE;
    
        l_dt_target_start schedule_outp.dt_target_tstz%TYPE;
        l_dt_target_end   schedule_outp.dt_target_tstz%TYPE;
        l_day             NUMBER := 0.99999;
        l_dt_server       VARCHAR2(30);
        l_date            TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp - 2;
    
    BEGIN
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        l_dt_target_start := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL);
        l_dt_target_end   := CAST(pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL) + l_day AS
                                  TIMESTAMP WITH LOCAL TIME ZONE);
    
        l_dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_active FOR
            SELECT ei.id_schedule,
                   ei.id_patient,
                   cr.num_clin_record,
                   ei.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epis.id_episode, ei.id_schedule) photo,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional),
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)) nick_name, --FM 2009/03/17
                   sp.flg_state,
                   pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, d.code_department) || ' - ' ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) dept,
                   pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon
              FROM schedule_outp    sp,
                   patient          pat,
                   clinical_service cs,
                   dept             dept,
                   department       d,
                   professional     p,
                   clin_record      cr,
                   epis_info        ei,
                   episode          epis,
                   professional     p1,
                   sys_domain       sd
             WHERE sp.dt_target_tstz BETWEEN l_dt_target_start AND l_dt_target_end
               AND sp.id_schedule_outp = ei.id_schedule_outp
               AND sp.flg_state != g_sched_adm_disch
               AND p.id_professional(+) = ei.id_professional
               AND ei.flg_sch_status != g_sched_canc
               AND ei.id_instit_requested = i_prof.institution
               AND pat.id_patient = ei.id_patient
               AND cs.id_clinical_service = epis.id_cs_requested
               AND d.id_department = epis.id_department_requested
               AND d.id_dept = dept.id_dept
               AND cr.id_patient = pat.id_patient
               AND cr.id_institution = i_prof.institution
               AND p1.id_professional(+) = ei.id_professional
               AND epis.id_episode(+) = ei.id_episode
               AND epis.flg_status = g_epis_active
               AND epis.dt_begin_tstz >= l_date
               AND sd.code_domain(+) = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd.val(+) = sp.flg_sched
               AND sd.id_language(+) = i_lang
                  --Complete non disclosure for VIP patients in order not to show in information patient grids
               AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != g_complete_non_disclosure)
            UNION --episódios sem agendamento (para visualizar episódios de urgência, internamento, etc) --SS 2007/04/26
            SELECT NULL id_schedule,
                   v.id_patient,
                   NULL num_clin_record,
                   epis.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epis.id_episode, ei.id_schedule) photo,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_date_utils.date_char_hour_tsz(i_lang, v.dt_begin_tstz, i_prof.institution, i_prof.software) dt_target,
                   CASE
                       WHEN epis.id_epis_type = 4 THEN
                        pk_prof_utils.get_main_prof(i_lang, i_prof, epis.id_episode)
                       ELSE
                        pk_prof_utils.get_name_signature(i_lang, i_prof, p1.id_professional) --FM 2009/03/17
                   END AS nick_name,
                   NULL flg_state,
                   pk_date_utils.date_send_tsz(i_lang, v.dt_begin_tstz, i_prof) dt_order,
                   NULL img_sched,
                   l_dt_server dt_server,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   decode(nvl(d.id_dept, -1),
                          -1,
                          pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || epis.id_epis_type),
                          pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || d.id_dept) || ' - ' ||
                          pk_translation.get_translation(i_lang, d.code_department) || ' - ' ||
                          pk_translation.get_translation(i_lang, cs.code_clinical_service)) dept,
                   pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon
              FROM patient pat, clinical_service cs, department d, epis_info ei, visit v, episode epis, professional p1
             WHERE v.id_institution = i_prof.institution
               AND v.id_visit = epis.id_visit
               AND pat.id_patient = v.id_patient
               AND epis.id_episode = ei.id_episode
               AND cs.id_clinical_service = epis.id_clinical_service
               AND epis.id_department = d.id_department
               AND epis.flg_status = g_epis_active
               AND epis.dt_begin_tstz >= l_date
               AND p1.id_professional(+) = ei.id_professional
                  --Complete non disclosure for VIP patients in order not to show in information patient grids
               AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != g_complete_non_disclosure)
             ORDER BY dt_order;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_INFORMATION',
                                              'INFORMATION_ACTIVE',
                                              o_error);
        
            pk_types.open_my_cursor(o_active);
        
            RETURN FALSE;
    END information_active;

    /********************************************************************************************
     * Detailed information of the selected episode
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_epis              Episode ID 
     * @param      i_pat               Patient ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_active            Detailed info 
     * @param      o_titles            Titles to show
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2005/12/26 
    **********************************************************************************************/

    FUNCTION information_active_det
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        i_pat    IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_active OUT pk_types.cursor_type,
        o_titles OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis IS
            SELECT e.id_episode, e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_epis
               AND e.flg_status = g_epis_active;
    
        CURSOR c_sched(l_epis IN episode.id_episode%TYPE) IS
            SELECT 'Y'
              FROM epis_info
             WHERE id_episode = l_epis
               AND id_schedule != -1;
    
        l_epis           episode.id_episode%TYPE;
        l_epis_type      episode.id_epis_type%TYPE;
        l_exist_sch      VARCHAR2(1);
        l_id_episode     episode.id_episode%TYPE;
        l_epis_type_oris VARCHAR2(1);
    
    BEGIN
        l_epis_type_oris := pk_sysconfig.get_config('ID_EPIS_TYPE_ORIS', i_prof);
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis, l_epis_type;
        CLOSE c_epis;
    
        l_id_episode := nvl(i_epis, l_epis);
    
        g_error := 'OPEN C_SCHED';
        OPEN c_sched(l_id_episode);
        FETCH c_sched
            INTO l_exist_sch;
        g_found := c_sched%FOUND;
        CLOSE c_sched;
    
        IF g_found
        THEN
            g_error := 'GET CURSOR O_TITLES';
            OPEN o_titles FOR
                SELECT pk_message.get_message(i_lang, 'GRID_INFO_T010') t_dt_target,
                       pk_message.get_message(i_lang, 'GRID_INFO_T011') t_nick_name,
                       pk_message.get_message(i_lang, 'GRID_INFO_T012') t_cons_type,
                       pk_message.get_message(i_lang, 'GRID_INFO_T013') t_dt_efectiv,
                       pk_message.get_message(i_lang, 'GRID_INFO_T014') t_desc_room,
                       pk_message.get_message(i_lang, 'GRID_INFO_T015') t_flg_state,
                       pk_message.get_message(i_lang, 'GRID_INFO_T017') t_analysis,
                       pk_message.get_message(i_lang, 'GRID_INFO_T016') t_exam,
                       pk_message.get_message(i_lang, 'GRID_INFO_T018') t_drug
                  FROM dual;
        
            IF l_epis_type = l_epis_type_oris
            THEN
                g_error := 'GET CURSOR O_ACTIVE; EXIST SCHEDULE; EPIS_TYPE_ORIS';
                OPEN o_active FOR
                    SELECT pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                           pk_prof_utils.get_main_prof(i_lang, i_prof, ei.id_episode) AS nick_name,
                           NULL cons_type,
                           pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                           pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_STATE', sp.flg_state, i_lang) flg_state,
                           decode(ar.id_episode,
                                  NULL,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) analysis,
                           decode(er.id_episode,
                                  NULL,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) exam,
                           decode(dp.id_episode,
                                  NULL,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) drug
                      FROM schedule_outp sp,
                           episode e,
                           epis_info ei,
                           room r,
                           (SELECT DISTINCT id_episode
                              FROM analysis_req
                             WHERE id_episode = l_id_episode
                               AND flg_time = g_flg_time_e
                               AND flg_status NOT IN (g_analy_req_res, g_analy_req_read, g_analy_req_canc)) ar,
                           (SELECT DISTINCT id_episode
                              FROM exam_req
                             WHERE id_episode = l_id_episode
                               AND flg_time = g_flg_time_e
                               AND flg_status NOT IN (g_exam_req_resu, g_exam_req_read, g_exam_req_canc)) er,
                           (SELECT l_id_episode id_episode
                              FROM dual
                             WHERE pk_api_pfh_clindoc_in.check_inf_prescription(i_lang, i_prof, l_id_episode) > 0) dp
                     WHERE e.id_episode = l_id_episode
                       AND e.flg_status = g_epis_active
                       AND ei.id_episode = e.id_episode
                       AND sp.id_schedule_outp = ei.id_schedule_outp
                       AND ei.flg_sch_status != g_sched_canc
                       AND e.id_epis_type = l_epis_type_oris
                       AND r.id_room = ei.id_room
                       AND ar.id_episode(+) = e.id_episode
                       AND er.id_episode(+) = e.id_episode
                       AND dp.id_episode(+) = e.id_episode;
            ELSE
                g_error := 'GET CURSOR O_ACTIVE; EXIST SCHEDULE';
                OPEN o_active FOR
                    SELECT pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name, --FM 2009/03/17
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                           pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                           pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_STATE', sp.flg_state, i_lang) flg_state,
                           decode(ar.flag,
                                  g_no,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) analysis,
                           decode(er.flag,
                                  g_no,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) exam,
                           decode(dp.flag,
                                  g_no,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) drug
                      FROM schedule_outp sp,
                           professional p,
                           episode e,
                           epis_info ei,
                           clinical_service cs,
                           room r,
                           (SELECT id_episode, flag
                              FROM (SELECT DISTINCT id_episode, g_yes flag
                                      FROM analysis_req
                                     WHERE id_episode = l_id_episode
                                       AND flg_time = g_flg_time_e
                                       AND flg_status NOT IN (g_analy_req_res, g_analy_req_read, g_analy_req_canc)
                                    UNION
                                    SELECT l_id_episode, g_no flag
                                      FROM dual
                                     ORDER BY 2 DESC)
                             WHERE rownum = 1) ar,
                           (SELECT id_episode, flag
                              FROM (SELECT DISTINCT id_episode, g_yes flag
                                      FROM exam_req
                                     WHERE id_episode = l_id_episode
                                       AND flg_time = g_flg_time_e
                                       AND flg_status NOT IN (g_exam_req_resu, g_exam_req_read, g_exam_req_canc)
                                    UNION
                                    SELECT l_id_episode, g_no flag
                                      FROM dual
                                     ORDER BY 2 DESC)
                             WHERE rownum = 1) er,
                           (SELECT id_episode, flag
                              FROM (SELECT l_id_episode id_episode, g_yes flag
                                      FROM dual
                                     WHERE pk_api_pfh_clindoc_in.check_inf_prescription(i_lang, i_prof, l_id_episode) > 0
                                    UNION ALL
                                    SELECT l_id_episode, g_no flag
                                      FROM dual
                                     ORDER BY 2 DESC)
                             WHERE rownum = 1) dp
                     WHERE e.id_episode = l_id_episode
                       AND e.flg_status = g_epis_active
                       AND ei.id_episode = e.id_episode
                       AND ei.flg_sch_status != g_sched_canc
                       AND sp.id_schedule_outp = ei.id_schedule_outp
                       AND p.id_professional(+) = ei.id_professional
                       AND cs.id_clinical_service = e.id_clinical_service
                       AND r.id_room = ei.id_room
                       AND ar.id_episode = e.id_episode
                       AND er.id_episode = e.id_episode
                       AND dp.id_episode = e.id_episode;
            END IF;
        ELSE
            g_error := 'GET CURSOR O_TITLES';
            OPEN o_titles FOR
                SELECT pk_message.get_message(i_lang, 'GRID_INFO_T010') t_dt_target,
                       pk_message.get_message(i_lang, 'GRID_INFO_T011') t_nick_name,
                       pk_message.get_message(i_lang, 'GRID_INFO_T021') t_cons_type,
                       pk_message.get_message(i_lang, 'GRID_INFO_T022') t_dt_efectiv,
                       pk_message.get_message(i_lang, 'GRID_INFO_T014') t_desc_room,
                       pk_message.get_message(i_lang, 'GRID_INFO_T015') t_flg_state,
                       pk_message.get_message(i_lang, 'GRID_INFO_T017') t_analysis,
                       pk_message.get_message(i_lang, 'GRID_INFO_T016') t_exam,
                       pk_message.get_message(i_lang, 'GRID_INFO_T018') t_drug
                  FROM dual;
        
            IF l_epis_type = l_epis_type_oris
            THEN
                g_error := 'GET CURSOR O_ACTIVE; NO SCHEDULE; EPIS_TYPE_ORIS';
                OPEN o_active FOR
                    SELECT pk_message.get_message(i_lang, 'COMMON_M018') dt_target,
                           pk_prof_utils.get_main_prof(i_lang, i_prof, e.id_episode) AS nick_name,
                           NULL cons_type,
                           pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                           pk_message.get_message(i_lang, 'COMMON_M018') flg_state,
                           decode(ar.id_episode,
                                  NULL,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) analysis,
                           decode(er.id_episode,
                                  NULL,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) exam,
                           decode(dp.id_episode,
                                  NULL,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) drug
                      FROM episode e,
                           epis_info ei,
                           department dep,
                           dept d,
                           room r,
                           (SELECT DISTINCT id_episode
                              FROM analysis_req
                             WHERE id_episode = l_id_episode
                               AND flg_time = g_flg_time_e
                               AND flg_status NOT IN (g_analy_req_res, g_analy_req_read, g_analy_req_canc)) ar,
                           (SELECT DISTINCT id_episode
                              FROM exam_req
                             WHERE id_episode = l_id_episode
                               AND flg_time = g_flg_time_e
                               AND flg_status NOT IN (g_exam_req_resu, g_exam_req_read, g_exam_req_canc)) er,
                           (SELECT l_id_episode id_episode
                              FROM dual
                             WHERE pk_api_pfh_clindoc_in.check_inf_prescription(i_lang, i_prof, l_id_episode) > 0) dp
                     WHERE e.id_episode = l_id_episode
                       AND e.flg_status = g_epis_active
                       AND ei.id_episode = e.id_episode
                       AND d.id_dept = dep.id_dept
                       AND d.id_institution = i_prof.institution
                       AND r.id_room = ei.id_room
                       AND e.id_epis_type = l_epis_type_oris
                       AND ar.id_episode(+) = e.id_episode
                       AND er.id_episode(+) = e.id_episode
                       AND dp.id_episode(+) = e.id_episode;
            ELSE
                g_error := 'GET CURSOR O_ACTIVE; NO SCHEDULE';
                OPEN o_active FOR
                    SELECT pk_message.get_message(i_lang, 'COMMON_M018') dt_target,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional), --FM 2009/03/17
                           get_clinical_service(i_lang, i_prof, e.id_episode) cons_type,
                           pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                           pk_message.get_message(i_lang, 'COMMON_M018') flg_state,
                           decode(ar.flag,
                                  g_no,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) analysis,
                           decode(er.flag,
                                  g_no,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) exam,
                           decode(dp.flag,
                                  g_no,
                                  pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                                  pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) drug
                      FROM professional p,
                           episode e,
                           epis_info ei,
                           room r,
                           (SELECT id_episode, flag
                              FROM (SELECT DISTINCT id_episode, g_yes flag
                                      FROM analysis_req
                                     WHERE id_episode = l_id_episode
                                       AND flg_time = g_flg_time_e
                                       AND flg_status NOT IN (g_analy_req_res, g_analy_req_read, g_analy_req_canc)
                                    UNION
                                    SELECT l_id_episode, g_no flag
                                      FROM dual
                                     ORDER BY 2 DESC)
                             WHERE rownum = 1) ar,
                           (SELECT id_episode, flag
                              FROM (SELECT DISTINCT id_episode, g_yes flag
                                      FROM exam_req
                                     WHERE id_episode = l_id_episode
                                       AND flg_time = g_flg_time_e
                                       AND flg_status NOT IN (g_exam_req_resu, g_exam_req_read, g_exam_req_canc)
                                    UNION
                                    SELECT l_id_episode, g_no flag
                                      FROM dual
                                     ORDER BY 2 DESC)
                             WHERE rownum = 1) er,
                           (SELECT id_episode, flag
                              FROM (SELECT l_id_episode id_episode, g_yes flag
                                      FROM dual
                                     WHERE pk_api_pfh_clindoc_in.check_inf_prescription(i_lang, i_prof, l_id_episode) > 0
                                    UNION
                                    SELECT l_id_episode, g_no flag
                                      FROM dual
                                     ORDER BY 2 DESC)
                             WHERE rownum = 1) dp
                     WHERE e.id_episode = l_id_episode
                       AND e.flg_status = g_epis_active
                       AND p.id_professional(+) = ei.id_professional
                       AND ei.id_episode = e.id_episode
                       AND r.id_room = ei.id_room
                       AND ar.id_episode = e.id_episode
                       AND er.id_episode = e.id_episode
                       AND dp.id_episode = e.id_episode;
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
                                              'PK_INFORMATION',
                                              'INFORMATION_ACTIVE_DET',
                                              o_error);
        
            pk_types.open_my_cursor(o_active);
            pk_types.open_my_cursor(o_titles);
        
            RETURN FALSE;
        
    END information_active_det;

    /********************************************************************************************
     * Information desk grid for inactive episodes: shows episodes with administrative discharge
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_dt                Schedule date. If is NULL, consider the actual date 
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_inactive          Inactive episodes 
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     CRS
     * @version    0.1
     * @since      2005/04/07 
    **********************************************************************************************/

    FUNCTION information_inactive
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_inactive  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_inactive FOR
            SELECT ei.id_schedule,
                   ei.id_patient,
                   cr.num_clin_record,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional), --FM 2009/03/17
                   ei.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epis.id_episode, ei.id_schedule) photo,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_date_utils.dt_chr_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target_day,
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target_hour,
                   pk_date_utils.to_char_insttimezone(i_prof, sp.dt_target_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   g_sysdate_char dt_server,
                   decode(instr(dep1.flg_type, 'I'),
                          '',
                          '',
                          pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                   pk_translation.get_translation(i_lang, drn.code_discharge_reason) || ': ' ||
                   decode(drt.id_discharge_dest,
                          '',
                          decode(drt.id_dep_clin_serv,
                                 '',
                                 decode(drt.id_institution,
                                        '',
                                        '',
                                        pk_translation.get_translation(i_lang, inst.code_institution)),
                                 pk_translation.get_translation(i_lang, dep1.code_department) || ' - ' ||
                                 pk_translation.get_translation(i_lang, cs1.code_clinical_service)),
                          pk_translation.get_translation(i_lang, ddn.code_discharge_dest)) disch_reason,
                   pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) dept,
                   pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon
              FROM schedule_outp    sp,
                   patient          pat,
                   clinical_service cs,
                   professional     p,
                   clin_record      cr,
                   epis_info        ei,
                   disch_reas_dest  drt,
                   dep_clin_serv    dcs1,
                   department       dep1,
                   dept             dept,
                   clinical_service cs1,
                   episode          epis,
                   discharge_reason drn,
                   discharge_dest   ddn,
                   institution      inst
             WHERE ei.id_schedule_outp = sp.id_schedule_outp
               AND ei.id_instit_requested = i_prof.institution
               AND ei.flg_sch_status != g_sched_canc
               AND pat.id_patient = ei.id_patient
               AND cs.id_clinical_service = epis.id_cs_requested
               AND dept.id_dept = epis.id_dept_requested
               AND cr.id_patient = pat.id_patient
               AND cr.id_institution = i_prof.institution
               AND p.id_professional(+) = ei.id_professional
               AND ei.flg_dsch_status != 'C'
               AND drt.id_disch_reas_dest = ei.id_disch_reas_dest
               AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv
               AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
               AND dep1.id_department(+) = dcs1.id_department
               AND epis.id_episode = ei.id_episode
               AND ei.flg_status = g_epis_inactive
               AND drn.id_discharge_reason = drt.id_discharge_reason
               AND ddn.id_discharge_dest(+) = drt.id_discharge_dest
               AND inst.id_institution(+) = drt.id_institution
               AND epis.dt_end_tstz BETWEEN current_timestamp - 2 AND current_timestamp
                  --Complete non disclosure for VIP patients in order not to show in information patient grids
               AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != g_complete_non_disclosure)
            UNION
            SELECT NULL id_schedule,
                   ei.id_patient,
                   cr.num_clin_record,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional), --FM 2009/03/17
                   ei.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epis.id_episode, ei.id_schedule) photo,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_date_utils.dt_chr_tsz(i_lang, v.dt_begin_tstz, i_prof) dt_target_day,
                   pk_date_utils.date_char_hour_tsz(i_lang, v.dt_begin_tstz, i_prof.institution, i_prof.software) dt_target_hour,
                   pk_date_utils.to_char_insttimezone(i_prof, v.dt_begin_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   g_sysdate_char dt_server,
                   decode(instr(dep1.flg_type, 'I'),
                          '',
                          '',
                          pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                   
                   pk_translation.get_translation(i_lang, drn.code_discharge_reason) || ': ' ||
                   decode(drt.id_discharge_dest,
                          '',
                          decode(drt.id_dep_clin_serv,
                                 '',
                                 decode(drt.id_institution,
                                        '',
                                        '',
                                        pk_translation.get_translation(i_lang, inst.code_institution)),
                                 pk_translation.get_translation(i_lang, dep1.code_department) || ' - ' ||
                                 pk_translation.get_translation(i_lang, cs1.code_clinical_service)),
                          pk_translation.get_translation(i_lang, ddn.code_discharge_dest)) disch_reason,
                   pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) dept,
                   pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, pat.id_patient, ei.id_episode) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon
              FROM patient          pat,
                   clinical_service cs,
                   professional     p,
                   clin_record      cr,
                   epis_info        ei,
                   disch_reas_dest  drt,
                   dep_clin_serv    dcs1,
                   department       dep1,
                   dept             dept,
                   clinical_service cs1,
                   episode          epis,
                   visit            v,
                   discharge_reason drn,
                   discharge_dest   ddn,
                   institution      inst
             WHERE v.id_institution = i_prof.institution
               AND pat.id_patient = v.id_patient
               AND epis.id_visit = v.id_visit
               AND cs.id_clinical_service = epis.id_clinical_service
               AND epis.id_dept = dept.id_dept
               AND cr.id_patient(+) = pat.id_patient
               AND cr.id_institution(+) = i_prof.institution
               AND p.id_professional(+) = ei.id_professional
               AND ei.flg_dsch_status = pk_alert_constant.g_active
               AND drt.id_disch_reas_dest = ei.id_disch_reas_dest
               AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv
               AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
               AND dep1.id_department(+) = dcs1.id_department
               AND epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_inactive
               AND drn.id_discharge_reason = drt.id_discharge_reason
               AND ddn.id_discharge_dest(+) = drt.id_discharge_dest
               AND inst.id_institution(+) = drt.id_institution
               AND epis.dt_end_tstz BETWEEN current_timestamp - 2 AND current_timestamp
                  --Complete non disclosure for VIP patients in order not to show in information patient grids
               AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != g_complete_non_disclosure)
             ORDER BY dt_ord1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_INFORMATION',
                                              'INFORMATION_INACTIVE',
                                              o_error);
        
            pk_types.open_my_cursor(o_inactive);
            RETURN FALSE;
    END information_inactive;

    /********************************************************************************************
     * Inactive episodes of the selected patient
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_pat               Patient ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_inactive          Inactive episodes
     * @param      o_error             Error
     *
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2005/12/26 
    **********************************************************************************************/

    FUNCTION information_inactive_det
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_inactive OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_inactive FOR
            SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_translation.get_translation(i_lang, drn.code_discharge_reason) || ': ' ||
                   decode(drt.id_discharge_dest,
                          '',
                          decode(drt.id_dep_clin_serv,
                                 '',
                                 decode(drt.id_institution,
                                        '',
                                        '',
                                        pk_translation.get_translation(i_lang, inst.code_institution)),
                                 pk_translation.get_translation(i_lang, dep.code_department) || ' - ' ||
                                 pk_translation.get_translation(i_lang, cs2.code_clinical_service)),
                          pk_translation.get_translation(i_lang, ddn.code_discharge_dest)) disch_reason,
                   pk_date_utils.dt_chr_tsz(i_lang, d.dt_med_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            pk_discharge_core.get_dt_admin(i_lang,
                                                                           i_prof,
                                                                           NULL,
                                                                           d.flg_status_adm,
                                                                           d.dt_admin_tstz),
                                            i_prof) dt_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    pk_discharge_core.get_dt_admin(i_lang,
                                                                                   i_prof,
                                                                                   NULL,
                                                                                   d.flg_status_adm,
                                                                                   d.dt_admin_tstz),
                                                    i_prof.institution,
                                                    i_prof.software) hr_target,
                   pk_date_utils.to_char_insttimezone(i_prof, d.dt_med_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_date_utils.to_char_insttimezone(i_prof,
                                                      pk_discharge_core.get_dt_admin(i_lang,
                                                                                     i_prof,
                                                                                     NULL,
                                                                                     d.flg_status_adm,
                                                                                     d.dt_admin_tstz),
                                                      'YYYYMMDDHH24MISS') dt_ord2
              FROM episode          e,
                   clinical_service cs,
                   clinical_service cs2,
                   discharge        d,
                   disch_reas_dest  drt,
                   discharge_reason drn,
                   discharge_dest   ddn,
                   department       dep,
                   institution      inst,
                   dep_clin_serv    dcs2
             WHERE e.id_patient = i_pat
               AND e.flg_status = g_epis_inactive
               AND cs.id_clinical_service = e.id_clinical_service
               AND d.id_episode = e.id_episode
               AND d.flg_status NOT IN
                   (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
               AND drt.id_disch_reas_dest = d.id_disch_reas_dest
               AND drn.id_discharge_reason = drt.id_discharge_reason
               AND ddn.id_discharge_dest(+) = drt.id_discharge_dest
               AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv
               AND dep.id_department(+) = dcs2.id_department
               AND cs2.id_clinical_service(+) = dcs2.id_clinical_service
               AND inst.id_institution(+) = drt.id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_INFORMATION',
                                              'INFORMATION_INACTIVE_DET',
                                              o_error);
        
            pk_types.open_my_cursor(o_inactive);
            RETURN FALSE;
    END information_inactive_det;

    /******************************************************************************
    Obter lista de critérios da pesquisa de pacientes.
    
    * @param      I_LANG                Identificação do Idioma
    * @param      I_ID_SYS_BUTTON       Identificação do botão
    * @param      I_PROF                Profissional
    * @param      O_LIST
    * @param      O_LIST_CS
    * @param      O_LIST_FS
    * @param      O_LIST_PAYMENT_STATE
    * @param      O_ERROR               erro
    * @return     boolean
    
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/04/27
    *********************************************************************************/

    FUNCTION get_pat_search_list
    (
        i_lang               IN language.id_language%TYPE,
        i_id_sys_button      IN search_screen.id_sys_button%TYPE,
        i_prof               IN profissional,
        o_list               OUT pk_types.cursor_type,
        o_list_cs            OUT pk_types.cursor_type,
        o_list_fs            OUT pk_types.cursor_type,
        o_list_payment_state OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_common_m002 VARCHAR2(4000);
    BEGIN
        -- FO 2008/05/24 Query reformulada para novo modelo de dados
        g_error := 'GET CURSOR CRITERIA';
        OPEN o_list FOR
            SELECT rank,
                   id_criteria,
                   desc_criteria,
                   flg_type,
                   flg_mandatory,
                   decode(flg_mandatory,
                          g_flg_mandatory,
                          REPLACE((SELECT pk_message.get_message(i_lang, 'SEARCH_CRITERIA_M002')
                                    FROM dual),
                                  '@1',
                                  desc_criteria),
                          NULL) mess_mandatory
            --,grid_name
              FROM (SELECT rank,
                           id_criteria,
                           (SELECT pk_translation.get_translation(i_lang, code_criteria)
                              FROM dual) desc_criteria,
                           flg_type,
                           flg_mandatory
                    --,grid_name
                      FROM search_screen
                      JOIN sscr_crit
                     USING (id_search_screen)
                      JOIN criteria
                     USING (id_criteria)
                     WHERE id_sys_button = i_id_sys_button
                       AND flg_available = g_search_avail
                     ORDER BY rank);
    
        l_msg_common_m002 := pk_message.get_message(i_lang, 'COMMON_M002');
        IF i_prof.software = 11
        THEN
            -- internamento / inpatient
        
            OPEN o_list_cs FOR
                SELECT dpt.id_department data,
                       1 rank,
                       pk_translation.get_translation(i_lang, dpt.code_department) label
                  FROM department dpt
                 WHERE dpt.id_institution = i_prof.institution
                   AND dpt.flg_available = g_flg_available
                   AND instr(dpt.flg_type, 'I') > 0
                UNION ALL
                SELECT -1 data, -1 rank, l_msg_common_m002 label
                  FROM dual
                 ORDER BY rank, label;
        
        ELSE
            OPEN o_list_cs FOR
                SELECT dcs.id_dep_clin_serv,
                       c.id_clinical_service data,
                       c.rank,
                       pk_translation.get_translation(i_lang, c.code_clinical_service) label
                  FROM clinical_service c, dep_clin_serv dcs, department dep, software_dept sd --SS 2006/11/28 , DEP_CLIN_SERV_TYPE DCST
                 WHERE dcs.id_clinical_service = c.id_clinical_service
                   AND dep.id_department = dcs.id_department
                   AND dep.id_institution = i_prof.institution
                   AND instr(dep.flg_type, 'C') > 0 --SS 2006/11/28
                   AND dep.id_department IN (SELECT id_department
                                               FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                                              WHERE pdcs.id_professional = i_prof.id
                                                AND pdcs.flg_status = g_selected
                                                AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv) --SS 2006/11/28
                   AND sd.id_dept = dep.id_dept --SS 2006/11/28
                UNION ALL
                SELECT -1 id_dep_clin_serv, -1 data, -1 rank, l_msg_common_m002 label
                  FROM dual
                 ORDER BY rank, label;
        END IF;
    
        g_error := 'GET CURSOR FIRST / SUBSEQUENT';
        OPEN o_list_fs FOR
            SELECT val data, rank, desc_val label
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_first_subs
               AND domain_owner = pk_sysdomain.k_default_schema
            UNION ALL
            SELECT '-1' data, -1 rank, l_msg_common_m002 label
              FROM dual
             ORDER BY rank, label;
    
        -- lgaspar 2007-fev-08
        g_error := 'GET PAYMENT STATE';
        IF (pk_sysdomain.get_domains_none_option(i_lang, g_flg_payment_domain, i_prof, o_list_payment_state, o_error) =
           FALSE)
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
                                              'PK_INFORMATION',
                                              'GET_PAT_SEARCH_LIST',
                                              o_error);
        
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_list_cs);
            pk_types.open_my_cursor(o_list_fs);
        
            RETURN FALSE;
    END get_pat_search_list;

    /********************************************************************************************
     * Search active patients that meet the selected criteria   
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_id_sys_btn_crit   Search criteria IDs  
     * @param      i_crit_val          Search criteria values    
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_dt                Search date. If is NULL, consider SYSDATE
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      o_flg_show          flag that indicates whether there's a message to show or not  
     * @param      o_msg               message to show
     * @param      o_msg_title         message title
     * @param      o_button            button to show 
     * @param      o_pat               active patients 
     * @param      o_mess_no_result    message to show if there are no results 
     * @param      o_error             error
     *
    
     * @value      o_flg_show          {*} 'Y' there's a message to show to the user
                                       {*} 'N' no message to show
     * @value      o_button            {*} 'R' read
                                       {*} 'N' no
                                       {*} 'C' confirmed
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2007/04/27
    **********************************************************************************************/

    FUNCTION get_pat_criteria_active
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN DATE,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(4000);
        l_error      t_error_out;
        v_where_cond VARCHAR2(4000);
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        aux_sql      VARCHAR2(4000);
        l_continue   BOOLEAN := TRUE;
        l_ret        BOOLEAN;
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show     := 'N';
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof); -- Nº MÁXIMO DE REGISTOS A APRESENTAR
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := '  ';
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
        
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
            
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
                l_where := l_where || v_where_cond;
            END IF;
        
        END LOOP;
    
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) 
										FROM EPISODE EPIS, PATIENT PAT, CLIN_RECORD CR,  EPIS_INFO EI, 
										SCHEDULE SCHED,CLINICAL_SERVICE CS,DEPARTMENT D, DEPT , PROFESSIONAL P,
                    DISCHARGE D1, DISCH_REAS_DEST DRT, INSTITUTION INST, DEPARTMENT DEP, DEP_CLIN_SERV DCS2, DISCHARGE_DEST DDN, CLINICAL_SERVICE CS2
										WHERE EPIS.FLG_STATUS= ''' || g_epis_active || '''' || '
										AND PAT.ID_PATIENT=EI.ID_PATIENT
										AND CR.ID_PATIENT(+)=PAT.ID_PATIENT
										AND CR.ID_INSTITUTION(+) = ' || i_prof.institution || '
										AND EI.ID_EPISODE=EPIS.ID_EPISODE
										AND sched.id_schedule(+) = ei.id_schedule
										AND cs.id_clinical_service = decode(epis.id_clinical_service, -1, epis.id_cs_requested, epis.id_clinical_service)
		                AND d.id_department = decode(epis.id_department, -1, epis.id_department_requested, epis.id_department)
										AND dept.id_dept = d.id_dept
										AND dept.id_institution = decode(dept.id_dept, -1, 0, ' || i_prof.institution || ')' ||
                   'AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL
										AND D1.ID_EPISODE(+)= EPIS.ID_EPISODE
										AND D1.DT_CANCEL_tstz(+) IS NULL
										AND D1.ID_PROF_ADMIN(+) IS NULL
										AND DRT.ID_DISCH_REAS_DEST(+) = D1.ID_DISCH_REAS_DEST
										AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION 
										AND DEP.ID_DEPARTMENT(+) = DCS2.ID_DEPARTMENT
										AND DCS2.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV
										AND CS2.ID_CLINICAL_SERVICE(+) = DCS2.ID_CLINICAL_SERVICE
										AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST
										 AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != ''' ||
                   g_complete_non_disclosure || ''' )' || l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE o_pat';
    
        EXECUTE IMMEDIATE aux_sql
            INTO l_count;
    
        g_error := 'COMPARE LIMIT';
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error := 'GET CURSOR o_pat';
            pk_alertlog.log_debug(g_error, 'PK_INFORMATION');
            OPEN o_pat FOR ' SELECT ' || ' pk_patient.get_pat_name( ' || i_lang || ', ' || ' profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), ' || ' pat.id_patient, ei.id_episode) name_pat, ' || ' pk_patient.get_pat_name_to_sort( ' || i_lang || ', ' || ' profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), ' || ' pat.id_patient, ei.id_episode) name_pat_sort, ' || ' PAT.GENDER, PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.ID_PATIENT, ' || i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, PK_PATPHOTO.GET_PAT_PHOTO( ' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), ' || ' PAT.ID_PATIENT, EPIS.ID_EPISODE, EI.ID_SCHEDULE ) PHOTO, ' || ' PK_DATE_UTILS.DATE_CHAR_HOUR_tsz(' || i_lang || ', EPIS.DT_BEGIN_tstz,' || i_prof.institution || ',' || i_prof.software || ') HOUR_TARGET, PK_DATE_UTILS.TRUNC_DT_CHAR_tsz(' || i_lang || ', EPIS.DT_BEGIN_tstz,' || i_prof.institution || ',' || i_prof.software || ') DATE_TARGET,
                       EPIS.ID_EPISODE, PAT.ID_PATIENT, 
											 pk_prof_utils.get_name_signature(' || i_lang || ',  
											 profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),  p.id_professional ) NICK_NAME,
											 SCHED.ID_SCHEDULE, CR.NUM_CLIN_RECORD,
                       pk_translation.get_translation(' || i_lang || ',dept.code_dept)|| '' - ''||
                       pk_translation.get_translation(' || i_lang || ', d.code_department)|| '' - '' ||
                       pk_translation.get_translation(' || i_lang || ', cs.code_clinical_service) CONS_TYPE,
                    DECODE(nvl(DRT.ID_DISCHARGE_DEST, 0), 0,
                                                   DECODE(nvl(DRT.ID_DEP_CLIN_SERV, 0), 0, 
                                                                                 DECODE(nvl(DRT.ID_INSTITUTION, 0), 0, '''', 
                                                                                                             PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', INST.CODE_INSTITUTION)), 
                                                                                 PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', DEP.CODE_DEPARTMENT)||'' - ''||PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ',CS2.CODE_CLINICAL_SERVICE)), 
                                                   PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ' ,DDN.CODE_DISCHARGE_DEST)) DISCH_DEST  
													FROM EPISODE EPIS, PATIENT PAT, CLIN_RECORD CR,  EPIS_INFO EI, 
													SCHEDULE SCHED,CLINICAL_SERVICE CS,DEPARTMENT D, DEPT , PROFESSIONAL P,
														DISCHARGE D1, DISCH_REAS_DEST DRT, INSTITUTION INST, DEPARTMENT DEP, DEP_CLIN_SERV DCS2, DISCHARGE_DEST DDN, CLINICAL_SERVICE CS2
													WHERE EPIS.FLG_STATUS= ''' || g_epis_active || '''' || '
													AND PAT.ID_PATIENT=EI.ID_PATIENT
													AND CR.ID_PATIENT(+)=PAT.ID_PATIENT
													AND CR.ID_INSTITUTION(+) = ' || i_prof.institution || '
													AND EI.ID_EPISODE=EPIS.ID_EPISODE
													AND sched.id_schedule(+) = ei.id_schedule
													AND cs.id_clinical_service = decode(epis.id_clinical_service, -1, epis.id_cs_requested, epis.id_clinical_service)
													AND d.id_department = decode(epis.id_department, -1, epis.id_department_requested, epis.id_department)
													AND dept.id_dept = d.id_dept
                          AND dept.id_institution = decode(dept.id_dept, -1, 0, ' || i_prof.institution || ')' || 'AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL
													AND D1.ID_EPISODE(+)= EPIS.ID_EPISODE
													AND D1.DT_CANCEL_tstz(+) IS NULL
													AND D1.ID_PROF_ADMIN(+) IS NULL
													AND DRT.ID_DISCH_REAS_DEST(+) = D1.ID_DISCH_REAS_DEST
													AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION 
													AND DEP.ID_DEPARTMENT(+) = DCS2.ID_DEPARTMENT
													AND DCS2.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV
													AND CS2.ID_CLINICAL_SERVICE(+) = DCS2.ID_CLINICAL_SERVICE
													AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST 
													AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST 
													AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST 
											   AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != ''' || g_complete_non_disclosure || ''' ) ' || l_where || ' AND ROWNUM < ' || l_limit;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, 'PK_INFORMATION', 'GET_PAT_CRITERIA_ACTIVE', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, 'PK_INFORMATION', 'GET_PAT_CRITERIA_ACTIVE', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_INFORMATION',
                                              'GET_PAT_CRITERIA_ACTIVE',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_active;

    /********************************************************************************************
     * Search inactive patients that meet the selected criteria   
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_id_sys_btn_crit   Search criteria IDs  
     * @param      i_crit_val          Search criteria values    
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_dt                Search date. If is NULL, consider SYSDATE
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      i_prof_cat_type     Professional's category type
     * @param      o_flg_show          Flag that indicates whether there's a message to show or not  
     * @param      o_msg               Message to show
     * @param      o_msg_title         Message title
     * @param      o_button            Button to show 
     * @param      o_pat               Inactive patients 
     * @param      o_mess_no_result    Message to show if there are no results 
     * @param      o_error             Error
     *
    
     * @value      o_flg_show          {*} 'Y' there's a message to show to the user
                                       {*} 'N' no message to show
     * @value      o_button            {*} 'R' read
                                       {*} 'N' no
                                       {*} 'C' confirmed
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2007/04/27
    **********************************************************************************************/

    FUNCTION get_pat_criteria_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN DATE,
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
    
        l_where      VARCHAR2(4000);
        l_error      t_error_out;
        v_where_cond VARCHAR2(4000);
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        aux_sql      VARCHAR2(4000);
        l_continue   BOOLEAN := TRUE;
        l_ret        BOOLEAN;
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show     := 'N';
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := '  ';
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
            
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) 
											FROM EPISODE EPIS, PATIENT PAT, CLIN_RECORD CR, EPIS_INFO EI, 
											SCHEDULE SCHED,CLINICAL_SERVICE CS,DEPARTMENT D, DEPT , PROFESSIONAL P, 
											DISCHARGE D1, DISCH_REAS_DEST DRT, INSTITUTION INST, DEPARTMENT DEP, DEP_CLIN_SERV DCS2, DISCHARGE_DEST DDN, CLINICAL_SERVICE CS2
											WHERE EPIS.FLG_STATUS= ''' || g_epis_inactive || '''' || '
											AND PAT.ID_PATIENT=EI.ID_PATIENT
											AND CR.ID_PATIENT(+)=PAT.ID_PATIENT
											AND CR.ID_INSTITUTION(+) = ' || i_prof.institution || '
											AND EI.ID_EPISODE=EPIS.ID_EPISODE
											AND sched.id_schedule(+) = ei.id_schedule
											AND cs.id_clinical_service = decode(epis.id_clinical_service, -1, epis.id_cs_requested, epis.id_clinical_service)
											AND d.id_department = decode(epis.id_department, -1, epis.id_department_requested, epis.id_department)
											AND dept.id_dept = d.id_dept
									  	AND dept.id_institution = decode(dept.id_dept, -1, 0, ' || i_prof.institution || ')' ||
                   'AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL
								   		AND D1.ID_EPISODE(+)= EPIS.ID_EPISODE
								  		AND D1.DT_CANCEL_tstz(+) IS NULL
								  		AND D1.ID_PROF_ADMIN(+) IS NULL
								  		AND DRT.ID_DISCH_REAS_DEST(+) = D1.ID_DISCH_REAS_DEST
											AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION 
											AND DEP.ID_DEPARTMENT(+) = DCS2.ID_DEPARTMENT
											AND DCS2.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV
											AND CS2.ID_CLINICAL_SERVICE(+) = DCS2.ID_CLINICAL_SERVICE
                      AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST
											AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != ''' ||
                   g_complete_non_disclosure || ''' ) ' || l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error := 'GET CURSOR o_pat';
            OPEN o_pat FOR ' SELECT ' || ' pk_patient.get_pat_name( ' || i_lang || ', ' || ' profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), ' || ' pat.id_patient, ei.id_episode) name_pat, ' || ' PAT.GENDER, ' || ' PK_PATIENT.GET_PAT_AGE(' || i_lang || ',PAT.ID_PATIENT,' || i_prof.institution || ',' || i_prof.software || ') PAT_AGE ,' || ' PK_PATPHOTO.GET_PAT_PHOTO(' || i_lang || ', ' || ' profissional( ' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '), ' || ' PAT.ID_PATIENT, EPIS.ID_EPISODE, EI.ID_SCHEDULE ' || ') PHOTO, ' || ' PK_DATE_UTILS.DATE_CHAR_HOUR_tsz(' || i_lang || ', EPIS.DT_BEGIN_tstz,' || i_prof.institution || ',' || i_prof.software || ') HOUR_TARGET, 
                                                   PK_DATE_UTILS.TRUNC_DT_CHAR_tsz(' || i_lang || ', EPIS.DT_BEGIN_tstz,' || i_prof.institution || ',' || i_prof.software || ') DATE_TARGET,
                       EPIS.ID_EPISODE, PAT.ID_PATIENT, 
											 pk_prof_utils.get_name_signature(' || i_lang || ',  
											 profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),  p.id_professional ) NICK_NAME,
											 SCHED.ID_SCHEDULE, CR.NUM_CLIN_RECORD,
                       pk_translation.get_translation(' || i_lang || ',dept.code_dept)|| '' - ''||
                       pk_translation.get_translation(' || i_lang || ', d.code_department)|| '' - '' ||
                       pk_translation.get_translation(' || i_lang || ', cs.code_clinical_service) CONS_TYPE,
                    DECODE(nvl(DRT.ID_DISCHARGE_DEST, 0), 0,
                                                   DECODE(nvl(DRT.ID_DEP_CLIN_SERV, 0), 0, 
                                                                                 DECODE(nvl(DRT.ID_INSTITUTION, 0), 0, '''', 
                                                                                                             PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', INST.CODE_INSTITUTION)), 
                                                                                 PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', DEP.CODE_DEPARTMENT)||'' - ''||PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ',CS2.CODE_CLINICAL_SERVICE)), 
                                                   PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ' ,DDN.CODE_DISCHARGE_DEST)) DISCH_DEST  
													FROM EPISODE EPIS, PATIENT PAT, CLIN_RECORD CR,  EPIS_INFO EI, 
													SCHEDULE SCHED,CLINICAL_SERVICE CS,DEPARTMENT D, DEPT , PROFESSIONAL P,
													DISCHARGE D1, DISCH_REAS_DEST DRT, INSTITUTION INST, DEPARTMENT DEP, DEP_CLIN_SERV DCS2, DISCHARGE_DEST DDN, CLINICAL_SERVICE CS2
													WHERE EPIS.FLG_STATUS= ''' || g_epis_inactive || '''' || '
													AND PAT.ID_PATIENT=EI.ID_PATIENT
													AND CR.ID_PATIENT(+)=PAT.ID_PATIENT
													AND CR.ID_INSTITUTION(+) = ' || i_prof.institution || '
													AND EI.ID_EPISODE=EPIS.ID_EPISODE
													AND sched.id_schedule(+) = ei.id_schedule
													AND cs.id_clinical_service = decode(epis.id_clinical_service, -1, epis.id_cs_requested, epis.id_clinical_service)
													AND d.id_department = decode(epis.id_department, -1, epis.id_department_requested, epis.id_department)
													AND dept.id_dept = d.id_dept
													AND dept.id_institution = decode(dept.id_dept, -1, 0, ' || i_prof.institution || ')' || 'AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL
													AND D1.ID_EPISODE(+)= EPIS.ID_EPISODE
													AND D1.DT_CANCEL_tstz(+) IS NULL
													AND D1.ID_PROF_ADMIN(+) IS NULL
													AND DRT.ID_DISCH_REAS_DEST(+) = D1.ID_DISCH_REAS_DEST
													AND INST.ID_INSTITUTION(+) = DRT.ID_INSTITUTION 
													AND DEP.ID_DEPARTMENT(+) = DCS2.ID_DEPARTMENT
													AND DCS2.ID_DEP_CLIN_SERV(+) = DRT.ID_DEP_CLIN_SERV
													AND CS2.ID_CLINICAL_SERVICE(+) = DCS2.ID_CLINICAL_SERVICE
													AND DDN.ID_DISCHARGE_DEST(+) = DRT.ID_DISCHARGE_DEST
											  AND (pat.non_disclosure_level IS NULL OR pat.non_disclosure_level != ''' || g_complete_non_disclosure || ''' ) ' || l_where || ' AND ROWNUM < ' || l_limit;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, 'PK_INFORMATION', 'GET_PAT_CRITERIA_INACTIVE', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, 'PK_INFORMATION', 'GET_PAT_CRITERIA_INACTIVE', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_INFORMATION',
                                              'GET_PAT_CRITERIA_INACTIVE',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_inactive;

    /********************************************************************************************
     * Search scheduled patients that meet the selected criteria   
     *
     * @param      i_lang              Preferred language ID for this professional
     * @param      i_id_sys_btn_crit   Search criteria IDs  
     * @param      i_crit_val          Search criteria values    
     * @param      i_instit            Institution ID 
     * @param      i_epis_type         Episode type ID
     * @param      i_prof              Object (professional ID, institution ID, software ID) 
     * @param      i_prof_cat_type     Professional's category type
     * @param      o_flg_show          Flag that indicates whether there's a message to show or not  
     * @param      o_msg               Message to show
     * @param      o_msg_title         Message title
     * @param      o_button            Button to show 
     * @param      o_pat               Scheduled patients 
     * @param      o_mess_no_result    Message to show if there are no results 
     * @param      o_error             Error
     *
    
     * @value      o_flg_show          {*} 'Y' there's a message to show to the user
                                       {*} 'N' no message to show
     * @value      o_button            {*} 'R' read
                                       {*} 'N' no
                                       {*} 'C' confirmed
    
     * @return                         true or false on success or error
    
     * @author     SS
     * @version    0.1
     * @since      2007/04/27
    **********************************************************************************************/

    FUNCTION get_pat_crit_sched
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
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
    
        l_where      VARCHAR2(4000);
        l_error      t_error_out;
        v_where_cond VARCHAR2(4000);
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        aux_sql      VARCHAR2(4000);
        id_doc       sys_config.value%TYPE;
        l_continue   BOOLEAN := TRUE;
        l_ret        BOOLEAN;
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof); -- Nº MÁXIMO DE REGISTOS A APRESENTAR
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := ' ';
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
            
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
    
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(ID_SCHEDULE) ' || 'FROM ( ' || 'SELECT SP.ID_SCHEDULE ' ||
                   'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                   'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                   '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' ||
                   ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' ||
                   'WHERE S.ID_INSTIT_REQUESTED = :1 ' || --I_PROF.INSTITUTION||
                   ' AND S.FLG_STATUS = :20' || -- G_SCHED_SCHEDULED 
                   ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' ||
                  --' AND TRUNC(SP.DT_TARGET_) >= TO_DATE(TO_CHAR(TRUNC(:11), ''YYYYMMDD''), ''YYYYMMDD'')' ||
                   ' AND pk_date_utils.trunc_insttimezone(:30, SP.DT_TARGET_TSTZ, null) >= pk_date_utils.trunc_insttimezone(:30, :11, null) ' ||
                  --IPROF / I_PROF / CURRENT_TIMESTAMP
                   ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                   ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                   ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                   ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' || ' AND CR.ID_PATIENT = PAT.ID_PATIENT' ||
                   ' AND CR.ID_INSTITUTION = :1 ' || --||I_PROF.INSTITUTION||
                   ' AND S.ID_SCHEDULE NOT IN (SELECT EI.ID_SCHEDULE FROM EPIS_INFO EI WHERE EI.ID_SCHEDULE IS NOT NULL)' ||
                   ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                   ' AND DE.ID_DOC_TYPE(+) = :9' || ' AND DE.FLG_STATUS(+) = :10' ||
                   ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' || ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' ||
                   ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                   ' AND SD.VAL = SP.FLG_SCHED' || ' AND SD.ID_LANGUAGE = :15' || l_where || ' UNION ' ||
                   'SELECT SP.ID_SCHEDULE ' ||
                   'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                   'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                   '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' ||
                   ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' ||
                   'WHERE S.ID_INSTIT_REQUESTED = :1 ' || --I_PROF.INSTITUTION||
                   ' AND S.FLG_STATUS = :20' || -- G_SCHED_SCHEDULED 
                   ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' || ' AND SP.FLG_STATE = :20' ||
                  --' AND TRUNC(SP.DT_TARGET) < TO_DATE(TO_CHAR(TRUNC(:11), ''YYYYMMDD''), ''YYYYMMDD'')' ||
                   ' AND pk_date_utils.trunc_insttimezone(:30, SP.DT_TARGET_TSTZ, null) < pk_date_utils.trunc_insttimezone(:30, :11, null) ' ||
                   ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                   ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                   ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                   ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' || ' AND CR.ID_PATIENT = PAT.ID_PATIENT' ||
                   ' AND CR.ID_INSTITUTION = :1 ' || --||I_PROF.INSTITUTION||
                   ' AND S.ID_SCHEDULE NOT IN (SELECT EI.ID_SCHEDULE FROM EPIS_INFO EI WHERE EI.ID_SCHEDULE IS NOT NULL)' ||
                   ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                   ' AND DE.ID_DOC_TYPE(+) = :9' || ' AND DE.FLG_STATUS(+) = :10' ||
                   ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' || ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' ||
                   ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                   ' AND SD.VAL = SP.FLG_SCHED' || ' AND SD.ID_LANGUAGE = :15' || l_where || ' )';
    
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.institution, g_sched_scheduled, i_prof, i_prof, current_timestamp, i_prof.institution, id_doc, g_doc_active, i_lang, i_prof.institution, g_sched_scheduled, g_sched_scheduled, i_prof, i_prof, current_timestamp, i_prof.institution, id_doc, g_doc_active, i_lang;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error := 'GET CURSOR';
            aux_sql := ' SELECT *  FROM ( SELECT S.ID_SCHEDULE, SG.ID_PATIENT, CR.NUM_CLIN_RECORD, ' ||
                       'PAT.NAME, PAT.GENDER, PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.ID_PATIENT, ' ||
                       i_prof.institution || ', ' || i_prof.software || ') PAT_AGE,' || ' PK_PATPHOTO.GET_PAT_PHOTO( ' ||
                       i_lang || ', profissional( ' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                       i_prof.software || '), ' || 'PAT.ID_PATIENT, EPIS.ID_EPISODE, EI.ID_SCHEDULE ) PHOTO, ' ||
                       'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE,' ||
                       'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' || i_lang || ', SP.DT_TARGET_TSTZ, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') HOUR_TARGET,' || 'PK_DATE_UTILS.TRUNC_DT_CHAR_TSZ(' || i_lang ||
                       ', SP.DT_TARGET_TSTZ, ' || i_prof.institution || ', ' || i_prof.software ||
                       ') DATE_TARGET,                      
											 pk_prof_utils.get_name_signature(' || i_lang || ',  
											 profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                       '),  p.id_professional ) NICK_NAME,
											 SP.FLG_STATE,' || '''' || g_sysdate_char || ''' DT_SERVER,' ||
                       'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME IMG_SCHED,' || 'PK_TRANSLATION.GET_TRANSLATION(' ||
                       i_lang || ', SPC.CODE_SPECIALITY) DESC_SPECIALITY, ' || 'PK_DATE_UTILS.TO_CHAR_INSTTIMEZONE(' ||
                       i_prof.institution || ', ' || i_prof.software ||
                       ', SP.DT_TARGET_TSTZ, ''YYYYMMDDHH24MISS'') DT_ORD1 ' ||
                       'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                       'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                       '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' ||
                       ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' ||
                       'WHERE S.ID_INSTIT_REQUESTED = ' || i_prof.institution || ' AND S.FLG_STATUS = ''' ||
                       g_sched_scheduled || '''' || --------------- alterado ss: 2006/07/24 
                       ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' || ' AND pk_date_utils.trunc_insttimezone(profissional(' ||
                       i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ') ' ||
                       ', SP.DT_TARGET_TSTZ, null) >= pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ', ' ||
                       i_prof.institution || ', ' || i_prof.software || ') ' || ', current_timestamp, null) ' ||
                       ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                       ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                       ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                       ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' || ' AND CR.ID_PATIENT = PAT.ID_PATIENT' ||
                       ' AND CR.ID_INSTITUTION = ' || i_prof.institution ||
                       ' AND S.ID_SCHEDULE NOT IN (SELECT EI.ID_SCHEDULE FROM EPIS_INFO EI WHERE EI.ID_SCHEDULE IS NOT NULL)' ||
                       ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                       ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || ' AND DE.FLG_STATUS(+) = ''' || g_doc_active || '''' ||
                       ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' ||
                       ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' || ' AND SD.VAL = SP.FLG_SCHED' ||
                       ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                       ' AND SD.ID_LANGUAGE = ' || i_lang || l_where || ' UNION ' ||
                       'SELECT S.ID_SCHEDULE, SG.ID_PATIENT, CR.NUM_CLIN_RECORD,' ||
                       'PAT.NAME, PAT.GENDER, PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.ID_PATIENT, ' ||
                       i_prof.institution || ', ' || i_prof.software || ') PAT_AGE,' || ' PK_PATPHOTO.GET_PAT_PHOTO(' ||
                       i_lang || ', ' || ' profissional( ' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                       i_prof.software || '), PAT.ID_PATIENT, EPIS.ID_EPISODE, EI.ID_SCHEDULE ' || ') PHOTO, ' ||
                       'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE,' ||
                       'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' || i_lang || ', SP.DT_TARGET_TSTZ, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') HOUR_TARGET,' || 'PK_DATE_UTILS.TRUNC_DT_CHAR_TSZ(' || i_lang ||
                       ', SP.DT_TARGET_TSTZ, ' || i_prof.institution || ', ' || i_prof.software ||
                       ') DATE_TARGET,
											 pk_prof_utils.get_name_signature(' || i_lang || ',  
											 profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                       '),  p.id_professional ) NICK_NAME,
                       SP.FLG_STATE,' || '''' || g_sysdate_char || ''' DT_SERVER,' ||
                       'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME IMG_SCHED,' || 'PK_TRANSLATION.GET_TRANSLATION(' ||
                       i_lang || ', SPC.CODE_SPECIALITY) DESC_SPECIALITY, ' || 'PK_DATE_UTILS.TO_CHAR_INSTTIMEZONE(' ||
                       i_prof.institution || ', ' || i_prof.software ||
                       ', SP.DT_TARGET_TSTZ, ''YYYYMMDDHH24MISS'') DT_ORD1 ' ||
                       'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                       'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                       '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' ||
                       ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' ||
                       'WHERE S.ID_INSTIT_REQUESTED = ' || i_prof.institution || ' AND S.FLG_STATUS = ''' ||
                       g_sched_scheduled || '''' || --------------- alterado ss: 2006/07/24 
                       ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' || ' AND SP.FLG_STATE = ''' || g_sched_scheduled || '''' ||
                       ' AND pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                       i_prof.software || ') ' ||
                       ', SP.DT_TARGET_TSTZ, null) < pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ', ' ||
                       i_prof.institution || ', ' || i_prof.software || ') ' || ', current_timestamp, null) ' ||
                       ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                       ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                       ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                       ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' || ' AND CR.ID_PATIENT = PAT.ID_PATIENT' ||
                       ' AND CR.ID_INSTITUTION = ' || i_prof.institution ||
                       ' AND S.ID_SCHEDULE NOT IN (SELECT EI.ID_SCHEDULE FROM EPIS_INFO EI WHERE EI.ID_SCHEDULE IS NOT NULL)' ||
                       ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                       ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || ' AND DE.FLG_STATUS(+) = ''' || g_doc_active || '''' ||
                       ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' ||
                       ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' || ' AND SD.VAL = SP.FLG_SCHED' ||
                       ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                       ' AND SD.ID_LANGUAGE = ' || i_lang || l_where || ' ) ' || ' WHERE ROWNUM < ' || l_limit ||
                       ' ORDER BY DATE_TARGET';
        
            OPEN o_pat FOR aux_sql;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, 'PK_INFORMATION', 'GET_PAT_CRIT_SCHED', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, 'PK_INFORMATION', 'GET_PAT_CRIT_SCHED', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_INFORMATION',
                                              'GET_PAT_CRIT_SCHED',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_crit_sched;

BEGIN
    g_patient_active     := 'A';
    g_pat_blood_active   := 'A';
    g_default_hplan_y    := 'Y';
    g_hplan_active       := 'A';
    g_epis_cancel        := 'C';
    g_no_triage          := 'N';
    g_epis_diag_act      := 'A';
    g_pat_allergy_cancel := 'C';
    g_pat_habit_cancel   := 'C';
    g_pat_problem_cancel := 'C';
    g_pat_notes_cancel   := 'C';
    g_category_avail     := 'Y';
    g_cat_prof           := 'Y';

    g_flg_without := 'YF';

    g_search_avail  := 'Y';
    g_flg_mandatory := 'Y';

    g_domain_first_subs := 'SCHEDULE_OUTP.FLG_TYPE';

    g_selected := 'S';

    g_flg_payment_domain := 'DISCHARGE.FLG_PAYMENT';
    g_flg_available      := 'Y';

    g_movem_term := 'F';

END pk_information;
/
