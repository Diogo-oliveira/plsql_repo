/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_mcdt IS

    FUNCTION get_mcdt_summary
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_start_record IN NUMBER DEFAULT NULL,
        i_num_records  IN NUMBER DEFAULT NULL,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE e.id_episode = i_episode
               AND v.id_visit = e.id_visit;
    
        CURSOR c_profile IS
            SELECT pt.flg_approach
              FROM profile_template pt, prof_profile_template ppt
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND ppt.id_profile_template = pt.id_profile_template
               AND lower(pt.intern_name_templ) NOT LIKE '%viewer%'; -- ASM: foi acrescentada esta linha porque n�o h� como saber se o software � viewer ou n�o
    
        l_lab_tests_top_result sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULTS_ON_TOP', i_prof);
        l_exams_top_result     sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_RESULTS_ON_TOP', i_prof);
    
        l_care sys_config.value%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof);
    
        l_visit   c_visit%ROWTYPE;
        l_profile profile_template.flg_approach%TYPE;
    
        l_msg_not_aplicable sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M036');
    
        l_start NUMBER(24) := 1;
        l_end   NUMBER(24) := 9999999999999999999999;
    
    BEGIN
    
        IF i_start_record IS NOT NULL
           AND i_num_records IS NOT NULL
        THEN
            l_start := i_start_record;
            l_end   := i_start_record + i_num_records - 1;
        END IF;
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        g_error := 'OPEN C_PROFILE';
        OPEN c_profile;
        FETCH c_profile
            INTO l_profile;
        CLOSE c_profile;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT id_exam_req_det,
                   id_exam,
                   flg_status,
                   flg_type,
                   TYPE,
                   desc_type,
                   desc_exam,
                   desc_diagnosis,
                   priority,
                   hr_begin,
                   dt_begin,
                   to_be_perform,
                   status_string,
                   id_task_dependency,
                   icon_name,
                   rank,
                   dt_ord
              FROM (SELECT id_exam_req_det,
                           id_exam,
                           flg_status,
                           flg_type,
                           TYPE,
                           desc_type,
                           desc_exam,
                           desc_diagnosis,
                           priority,
                           hr_begin,
                           dt_begin,
                           to_be_perform,
                           status_string,
                           rank,
                           id_task_dependency,
                           icon_name,
                           dt_ord,
                           rownum rn
                      FROM (SELECT DISTINCT eea.id_exam_req_det id_exam_req_det,
                                            eea.id_exam,
                                            decode(eea.flg_status_det,
                                                   pk_exam_constant.g_exam_result,
                                                   pk_alert_constant.g_flg_status_f,
                                                   pk_exam_constant.g_exam_read,
                                                   pk_alert_constant.g_flg_status_f,
                                                   pk_alert_constant.g_flg_status_r) flg_status,
                                            g_exams flg_type,
                                            pk_sysdomain.get_img(i_lang, 'MCDT.FLG_TYPE', g_exams) TYPE,
                                            pk_sysdomain.get_domain(i_lang, i_prof, 'MCDT.FLG_TYPE', g_exams, NULL) desc_type,
                                            pk_exams_api_db.get_alias_translation(i_lang,
                                                                                  i_prof,
                                                                                  'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                                  NULL) ||
                                            decode(l_visit.id_epis_type,
                                                   nvl(t_ti_log.get_epis_type(i_lang,
                                                                              i_prof,
                                                                              e.id_epis_type,
                                                                              eea.flg_status_req,
                                                                              eea.id_exam_req,
                                                                              pk_exam_constant.g_exam_type_req),
                                                       e.id_epis_type),
                                                   '',
                                                   ' - (' || pk_message.get_message(i_lang,
                                                                                    profissional(i_prof.id,
                                                                                                 i_prof.institution,
                                                                                                 t_ti_log.get_epis_type_soft(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_epis_type,
                                                                                                                             eea.flg_status_req,
                                                                                                                             eea.id_exam_req,
                                                                                                                             pk_exam_constant.g_exam_type_req)),
                                                                                    'IMAGE_T009') || ')') desc_exam,
                                            decode(eea.flg_time,
                                                   pk_exam_constant.g_flg_time_r,
                                                   l_msg_not_aplicable,
                                                   pk_diagnosis.concat_diag(i_lang,
                                                                            eea.id_exam_req_det,
                                                                            NULL,
                                                                            NULL,
                                                                            i_prof)) desc_diagnosis,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'EXAM_REQ.PRIORITY',
                                                                    eea.priority,
                                                                    NULL) priority,
                                            decode(eea.flg_time,
                                                   pk_exam_constant.g_flg_time_r,
                                                   (SELECT pk_date_utils.dt_chr_hour(i_lang, de.dt_emited, i_prof)
                                                      FROM doc_external de, exam_media_archive ema
                                                     WHERE de.id_doc_external = ema.id_doc_external
                                                       AND ema.id_exam_result = eea.id_exam_result
                                                       AND rownum = 1),
                                                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                    eea.dt_begin,
                                                                                    i_prof.institution,
                                                                                    i_prof.software)) hr_begin,
                                            decode(eea.flg_time,
                                                   pk_exam_constant.g_flg_time_r,
                                                   (SELECT pk_date_utils.dt_chr(i_lang, de.dt_emited, i_prof)
                                                      FROM doc_external de, exam_media_archive ema
                                                     WHERE de.id_doc_external = ema.id_doc_external
                                                       AND ema.id_exam_result = eea.id_exam_result
                                                       AND rownum = 1),
                                                   pk_date_utils.dt_chr_tsz(i_lang,
                                                                            eea.dt_begin,
                                                                            i_prof.institution,
                                                                            i_prof.software)) dt_begin,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'EXAM_REQ.FLG_TIME',
                                                                    eea.flg_time,
                                                                    NULL) to_be_perform,
                                            decode(eea.flg_type, pk_exam_constant.g_type_img, 10, 11) ||
                                            pk_utils.get_status_string(i_lang,
                                                                       i_prof,
                                                                       eea.status_str,
                                                                       eea.status_msg,
                                                                       eea.status_icon,
                                                                       eea.status_flg) status_string,
                                            eea.id_task_dependency,
                                            pk_sysdomain.get_img(i_lang,
                                                                 'EXAM_REQ_DET.FLG_REQ_ORIGIN_MODULE',
                                                                 eea.flg_req_origin_module) icon_name,
                                            decode(eea.flg_status_det,
                                                   pk_exam_constant.g_exam_result,
                                                   decode(l_exams_top_result,
                                                          pk_exam_constant.g_yes,
                                                          0,
                                                          row_number()
                                                          over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'EXAM_REQ_DET.FLG_STATUS',
                                                                                     eea.flg_status_det),
                                                               coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)),
                                                   pk_exam_constant.g_exam_req,
                                                   row_number()
                                                   over(ORDER BY decode(eea.flg_referral,
                                                               NULL,
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'EXAM_REQ_DET.FLG_STATUS',
                                                                                     eea.flg_status_det),
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'EXAM_REQ_DET.FLG_REFERRAL',
                                                                                     eea.flg_referral)),
                                                        coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                                                   row_number()
                                                   over(ORDER BY decode(eea.flg_referral,
                                                               NULL,
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'EXAM_REQ_DET.FLG_STATUS',
                                                                                     eea.flg_status_det),
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'EXAM_REQ_DET.FLG_REFERRAL',
                                                                                     eea.flg_referral)),
                                                        coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)) rank,
                                            pk_date_utils.date_send_tsz(i_lang,
                                                                        coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req),
                                                                        i_prof) dt_ord
                              FROM exams_ea eea, episode e
                             WHERE e.id_visit = l_visit.id_visit
                               AND (e.id_episode = eea.id_episode OR e.id_episode = eea.id_episode_origin)
                               AND eea.flg_time != pk_exam_constant.g_flg_time_r
                               AND eea.flg_status_det NOT IN
                                   (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_read)
                            UNION ALL
                            SELECT DISTINCT ltea.id_analysis_req_det id_exam_req_det,
                                            ltea.id_analysis id_exam,
                                            decode(ltea.flg_status_det,
                                                   pk_alert_constant.g_analysis_det_result,
                                                   pk_alert_constant.g_flg_status_f,
                                                   pk_alert_constant.g_analysis_det_read,
                                                   pk_alert_constant.g_flg_status_f,
                                                   pk_alert_constant.g_flg_status_r) flg_status,
                                            g_lab_tests flg_type,
                                            pk_sysdomain.get_img(i_lang, 'MCDT.FLG_TYPE', g_lab_tests) TYPE,
                                            pk_sysdomain.get_domain(i_lang, i_prof, 'MCDT.FLG_TYPE', g_lab_tests, NULL) desc_type,
                                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      pk_lab_tests_constant.g_analysis_alias,
                                                                                      'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                      ltea.id_analysis,
                                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                      ltea.id_sample_type,
                                                                                      NULL) ||
                                            decode(l_visit.id_epis_type,
                                                   nvl(t_ti_log.get_epis_type(i_lang,
                                                                              i_prof,
                                                                              e.id_epis_type,
                                                                              ltea.flg_status_det,
                                                                              ltea.id_analysis_req_det,
                                                                              pk_alert_constant.g_analysis_type_req_det),
                                                       e.id_epis_type),
                                                   '',
                                                   ' - (' || pk_message.get_message(i_lang,
                                                                                    profissional(i_prof.id,
                                                                                                 i_prof.institution,
                                                                                                 t_ti_log.get_epis_type_soft(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_epis_type,
                                                                                                                             ltea.flg_status_det,
                                                                                                                             ltea.id_analysis_req_det,
                                                                                                                             pk_alert_constant.g_analysis_type_req_det)),
                                                                                    'IMAGE_T009') || ')') desc_exam,
                                            decode(ltea.flg_time_harvest,
                                                   pk_exam_constant.g_flg_time_r,
                                                   l_msg_not_aplicable,
                                                   pk_diagnosis.concat_diag(i_lang,
                                                                            NULL,
                                                                            ltea.id_analysis_req_det,
                                                                            NULL,
                                                                            i_prof)) desc_diagnosis,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'ANALYSIS_REQ_DET.FLG_URGENCY',
                                                                    ltea.flg_priority,
                                                                    NULL) priority,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             ltea.dt_target,
                                                                             i_prof.institution,
                                                                             i_prof.software) hr_begin,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     ltea.dt_target,
                                                                     i_prof.institution,
                                                                     i_prof.software) dt_begin,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'ANALYSIS_REQ.FLG_TIME',
                                                                    ltea.flg_time_harvest,
                                                                    NULL) to_be_perform,
                                            pk_utils.get_status_string(i_lang,
                                                                       i_prof,
                                                                       ltea.status_str,
                                                                       ltea.status_msg,
                                                                       ltea.status_icon,
                                                                       ltea.status_flg) status_string,
                                            ltea.id_task_dependency,
                                            pk_sysdomain.get_img(i_lang,
                                                                 'ANALYSIS_REQ_DET.FLG_REQ_ORIGIN_MODULE',
                                                                 ltea.flg_req_origin_module) icon_name,
                                            decode(ltea.flg_status_det,
                                                   pk_lab_tests_constant.g_analysis_result,
                                                   decode(l_lab_tests_top_result,
                                                          pk_lab_tests_constant.g_yes,
                                                          0,
                                                          row_number()
                                                          over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                     ltea.flg_status_det),
                                                               coalesce(ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) DESC)),
                                                   pk_lab_tests_constant.g_analysis_req,
                                                   row_number()
                                                   over(ORDER BY decode(ltea.flg_referral,
                                                               NULL,
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                     ltea.flg_status_det),
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                                     ltea.flg_referral)),
                                                        coalesce(ltea.dt_pend_req, ltea.dt_target, ltea.dt_req)),
                                                   row_number()
                                                   over(ORDER BY decode(ltea.flg_referral,
                                                               NULL,
                                                               decode(ltea.flg_status_det,
                                                                      pk_lab_tests_constant.g_analysis_toexec,
                                                                      pk_sysdomain.get_rank(i_lang,
                                                                                            'HARVEST.FLG_STATUS',
                                                                                            ltea.flg_status_harvest),
                                                                      pk_sysdomain.get_rank(i_lang,
                                                                                            'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                            ltea.flg_status_det)),
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                                     ltea.flg_referral)),
                                                        coalesce(ltea.dt_pend_req, ltea.dt_target, ltea.dt_req) DESC)) rank,
                                            pk_date_utils.date_send_tsz(i_lang,
                                                                        coalesce(ltea.dt_pend_req,
                                                                                 ltea.dt_target,
                                                                                 ltea.dt_req),
                                                                        i_prof) dt_ord
                              FROM lab_tests_ea ltea, episode e
                             WHERE e.id_visit = l_visit.id_visit
                               AND (e.id_episode = ltea.id_episode OR e.id_episode = ltea.id_episode_origin)
                               AND ltea.flg_status_det NOT IN
                                   (pk_lab_tests_constant.g_analysis_cancel, pk_lab_tests_constant.g_analysis_read)
                            UNION ALL
                            SELECT DISTINCT pea.id_interv_presc_det id_exam_req_det,
                                            pea.id_intervention id_exam,
                                            decode(pea.flg_status_det,
                                                   pk_procedures_constant.g_interv_finished,
                                                   pk_alert_constant.g_flg_status_f,
                                                   pk_procedures_constant.g_interv_interrupted,
                                                   pk_alert_constant.g_flg_status_f,
                                                   pk_alert_constant.g_flg_status_r) flg_status,
                                            g_other_procedures flg_type,
                                            pk_sysdomain.get_img(i_lang, 'MCDT.FLG_TYPE', pk_mcdt.g_other_procedures) TYPE,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'MCDT.FLG_TYPE',
                                                                    g_other_procedures,
                                                                    NULL) desc_type,
                                            pk_procedures_api_db.get_alias_translation(i_lang,
                                                                                       i_prof,
                                                                                       'INTERVENTION.CODE_INTERVENTION.' ||
                                                                                       pea.id_intervention,
                                                                                       NULL) ||
                                            decode(l_visit.id_epis_type,
                                                   nvl(t_ti_log.get_epis_type(i_lang,
                                                                              i_prof,
                                                                              e.id_epis_type,
                                                                              pea.flg_status_det,
                                                                              pea.id_interv_presc_det,
                                                                              pk_procedures_constant.g_interv_type_req),
                                                       e.id_epis_type),
                                                   '',
                                                   ' - (' || pk_message.get_message(i_lang,
                                                                                    profissional(i_prof.id,
                                                                                                 i_prof.institution,
                                                                                                 t_ti_log.get_epis_type_soft(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_epis_type,
                                                                                                                             pea.flg_status_det,
                                                                                                                             pea.id_interv_presc_det,
                                                                                                                             pk_procedures_constant.g_interv_type_req)),
                                                                                    'IMAGE_T009') || ')') desc_exam,
                                            pk_diagnosis.concat_diag(i_lang, NULL, NULL, pea.id_interv_presc_det, i_prof) desc_diagnosis,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'INTERV_PRESC_DET.FLG_PRTY',
                                                                    pea.flg_prty,
                                                                    NULL) priority,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             pea.dt_plan,
                                                                             i_prof.institution,
                                                                             i_prof.software) hr_begin,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     pea.dt_plan,
                                                                     i_prof.institution,
                                                                     i_prof.software) dt_begin,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'INTERV_PRESCRIPTION.FLG_TIME',
                                                                    pea.flg_time,
                                                                    NULL) to_be_perform,
                                            7 || pk_utils.get_status_string(i_lang,
                                                                            i_prof,
                                                                            pea.status_str,
                                                                            pea.status_msg,
                                                                            pea.status_icon,
                                                                            pea.status_flg) status_string,
                                            NULL id_task_dependency,
                                            NULL icon_name,
                                            decode(pea.flg_status_det,
                                                   pk_exam_constant.g_exam_req,
                                                   row_number()
                                                   over(ORDER BY decode(nvl(pea.flg_referral,
                                                                   pk_procedures_constant.g_flg_referral_a),
                                                               pk_procedures_constant.g_flg_referral_a,
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'INTERV_PRESC_DET.FLG_STATUS',
                                                                                     pea.flg_status_det),
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'INTERV_PRESC_DET.FLG_REFERRAL',
                                                                                     pea.flg_referral)),
                                                        dt_interv_prescription),
                                                   row_number()
                                                   over(ORDER BY decode(nvl(pea.flg_referral,
                                                                   pk_procedures_constant.g_flg_referral_a),
                                                               pk_procedures_constant.g_flg_referral_a,
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'INTERV_PRESC_DET.FLG_STATUS',
                                                                                     pea.flg_status_det),
                                                               pk_sysdomain.get_rank(i_lang,
                                                                                     'INTERV_PRESC_DET.FLG_REFERRAL',
                                                                                     pea.flg_referral)),
                                                        dt_interv_prescription DESC)) rank,
                                            pk_date_utils.date_send_tsz(i_lang, pea.dt_interv_prescription, i_prof) dt_ord
                              FROM procedures_ea pea
                              JOIN episode e
                                ON (e.id_episode = pea.id_episode OR e.id_episode = pea.id_episode_origin)
                             WHERE e.id_visit = l_visit.id_visit
                               AND (i_prof.software = l_care OR l_profile = 'S')
                               AND pea.flg_status_det NOT IN
                                   (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_finished)
                            UNION ALL
                            SELECT DISTINCT ntr.id_nurse_tea_req id_exam_req_det,
                                            NULL id_exam,
                                            decode(ntr.flg_status,
                                                   pk_patient_education_constant.g_nurse_tea_req_fin,
                                                   pk_alert_constant.g_flg_status_f,
                                                   pk_alert_constant.g_flg_status_r) flg_status,
                                            g_patient_education flg_type,
                                            pk_sysdomain.get_img(i_lang, 'MCDT.FLG_TYPE', pk_mcdt.g_patient_education) TYPE,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'MCDT.FLG_TYPE',
                                                                    g_patient_education,
                                                                    NULL) desc_type,
                                            pk_translation.get_translation(i_lang,
                                                                           CASE
                                                                               WHEN nts.code_nurse_tea_subject IS NULL THEN
                                                                                'NURSE_TEA_TOPIC.CODE_NURSE_TEA_TOPIC.1'
                                                                               ELSE
                                                                                nts.code_nurse_tea_subject
                                                                           END) desc_exam,
                                            pk_patient_education_api_db.get_diagnosis(i_lang,
                                                                                      i_prof,
                                                                                      ntr.id_nurse_tea_req) desc_diagnosis,
                                            NULL priority,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             ntr.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software) hr_begin,
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     ntr.dt_begin_tstz,
                                                                     i_prof.institution,
                                                                     i_prof.software) dt_begin,
                                            pk_sysdomain.get_domain(i_lang,
                                                                    i_prof,
                                                                    'NURSE_TEA_REQ.FLG_TIME',
                                                                    ntr.flg_time,
                                                                    NULL) to_be_perform,
                                            15 || pk_utils.get_status_string(i_lang,
                                                                             i_prof,
                                                                             ntr.status_str,
                                                                             ntr.status_msg,
                                                                             ntr.status_icon,
                                                                             ntr.status_flg) status_string,
                                            NULL id_task_dependency,
                                            NULL icon_name,
                                            row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang, 'NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status), ntr.dt_nurse_tea_req_tstz) rank,
                                            pk_date_utils.date_send_tsz(i_lang, ntr.dt_nurse_tea_req_tstz, i_prof) dt_ord
                              FROM nurse_tea_req ntr
                              LEFT JOIN nurse_tea_topic ntt
                                ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
                              LEFT JOIN nurse_tea_subject nts
                                ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
                              JOIN episode e
                                ON e.id_episode = ntr.id_episode
                             WHERE e.id_visit = l_visit.id_visit
                               AND (i_prof.software = l_care OR l_profile = 'S')
                               AND ntr.flg_status NOT IN
                                   (pk_alert_constant.g_flg_status_c, pk_alert_constant.g_flg_status_f)
                             ORDER BY flg_type, rank, dt_ord DESC)) t
             WHERE t.rn BETWEEN l_start AND l_end;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MCDT_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_mcdt_summary;

    FUNCTION get_mcdt_summary_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_list_count OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_visit IS
            SELECT v.id_visit, e.id_epis_type
              FROM episode e, visit v
             WHERE e.id_episode = i_episode
               AND v.id_visit = e.id_visit;
    
        CURSOR c_profile IS
            SELECT pt.flg_approach
              FROM profile_template pt, prof_profile_template ppt
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND ppt.id_profile_template = pt.id_profile_template
               AND lower(pt.intern_name_templ) NOT LIKE '%viewer%'; -- ASM: foi acrescentada esta linha porque n�o h� como saber se o software � viewer ou n�o
    
        l_care sys_config.value%TYPE := pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof);
    
        l_visit   c_visit%ROWTYPE;
        l_profile profile_template.flg_approach%TYPE;
    
    BEGIN
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        g_error := 'OPEN C_PROFILE';
        OPEN c_profile;
        FETCH c_profile
            INTO l_profile;
        CLOSE c_profile;
    
        g_error := 'OPEN O_LIST';
        SELECT SUM(list_count)
          INTO o_list_count
          FROM (SELECT DISTINCT COUNT(*) list_count
                  FROM exams_ea eea, episode e
                 WHERE e.id_visit = l_visit.id_visit
                   AND (e.id_episode = eea.id_episode OR e.id_episode = eea.id_episode_origin)
                   AND eea.flg_time != pk_exam_constant.g_flg_time_r
                   AND eea.flg_status_det NOT IN (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_read)
                UNION ALL
                SELECT DISTINCT COUNT(*) list_count
                  FROM lab_tests_ea ltea, episode e
                 WHERE e.id_visit = l_visit.id_visit
                   AND (e.id_episode = ltea.id_episode OR e.id_episode = ltea.id_episode_origin)
                   AND ltea.flg_status_det NOT IN
                       (pk_alert_constant.g_flg_status_c, pk_lab_tests_constant.g_analysis_read)
                UNION ALL
                SELECT DISTINCT COUNT(*) list_count
                  FROM procedures_ea pea
                  JOIN episode e
                    ON (e.id_episode = pea.id_episode OR e.id_episode = pea.id_episode_origin)
                 WHERE e.id_visit = l_visit.id_visit
                   AND (i_prof.software = l_care OR l_profile = 'S')
                   AND pea.flg_status_det NOT IN
                       (pk_procedures_constant.g_interv_cancel, pk_procedures_constant.g_interv_finished)
                UNION ALL
                SELECT DISTINCT COUNT(*) list_count
                  FROM nurse_tea_req ntr
                  JOIN episode e
                    ON e.id_episode = ntr.id_episode
                 WHERE e.id_visit = l_visit.id_visit
                   AND (i_prof.software = l_care OR l_profile = 'S')
                   AND ntr.flg_status NOT IN (pk_alert_constant.g_flg_status_c, pk_alert_constant.g_flg_status_f));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MCDT_SUMMARY_COUNT',
                                              o_error);
            RETURN FALSE;
    END get_mcdt_summary_count;

    /********************************************************************************************
    * Returns a list of workflow items of different areas
    *
    * @param   I_LANG               language id        
    * @param   I_PROF               professional, institution and software ids        
    * @param   I_ID_PATIENT         patient id        
    * @param   I_VIEWER_AREA        record date
    * @param   I_EPISODE            episode ID        
    *
    * @RETURN  Cursor containing list of items
    **********************************************************************************************/
    FUNCTION get_ordered_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list                     pk_types.cursor_type;
        l_id_execution             NUMBER;
        l_id                       NUMBER;
        l_num_count                NUMBER;
        l_code_description         VARCHAR2(4000);
        l_description              VARCHAR2(4000);
        l_code_title               VARCHAR2(4000);
        l_dt_req_tstz              TIMESTAMP WITH TIME ZONE;
        l_dt_req                   VARCHAR2(50 CHAR);
        l_flg_status               VARCHAR2(4000);
        l_msg_notes                VARCHAR2(4000);
        l_tooltip_title_notes_tech VARCHAR2(4000);
        l_tooltip_text_notes_tech  VARCHAR2(4000);
        l_tooltip_title_notes_pat  VARCHAR2(4000);
        l_tooltip_text_notes_pat   VARCHAR2(4000);
        l_tooltip_title_lab_test   VARCHAR2(4000);
        l_tooltip_text_lab_test    VARCHAR2(4000);
        l_flg_type                 VARCHAR2(4000);
        l_desc_status              VARCHAR2(4000);
        l_desc                     VARCHAR2(4000);
        l_rank                     NUMBER;
        l_rank_order               NUMBER;
        l_count                    NUMBER;
        l_instr_bg_color           VARCHAR2(200);
        l_instr_bg_alpha           VARCHAR2(200);
        l_icon_skinning            VARCHAR2(200 CHAR);
        l_task_title               VARCHAR2(200 CHAR);
    
        invoking_external_prc_error EXCEPTION;
        l_params VARCHAR2(1000 CHAR);
    
    BEGIN
        l_params := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient=' || i_id_patient ||
                    ' i_viewer_area=' || i_viewer_area || ' i_episode=' || i_episode;
        g_error  := 'Init get_ordered_list / ' || l_params;
    
        SELECT seq_gen_area_rank.nextval
          INTO l_id_execution
          FROM dual;
    
        g_error := 'PK_EXAMS_EXTERNAL_API_DB.GET_ORDERED_LIST / ' || l_params;
        IF pk_exams_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_patient      => i_id_patient,
                                                     i_viewer_area  => i_viewer_area,
                                                     i_episode      => i_episode,
                                                     o_ordered_list => l_list,
                                                     o_error        => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_code_title,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_count,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     title,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_code_title,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        g_error := 'PK_LAB_TESTS_EXTERNAL_API_DB.GET_ORDERED_LIST / ' || l_params;
        IF pk_lab_tests_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_patient      => i_id_patient,
                                                         i_viewer_area  => i_viewer_area,
                                                         i_episode      => i_episode,
                                                         o_ordered_list => l_list,
                                                         o_error        => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_msg_notes,
                         l_tooltip_title_notes_tech,
                         l_tooltip_text_notes_tech,
                         l_tooltip_title_notes_pat,
                         l_tooltip_text_notes_pat,
                         l_tooltip_title_lab_test,
                         l_tooltip_text_lab_test,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     dt_req_tstz,
                     flg_status,
                     msg_notes,
                     tooltip_title_notes_tech,
                     tooltip_text_notes_tech,
                     tooltip_title_notes_pat,
                     tooltip_text_notes_pat,
                     tooltip_title_lab_test,
                     tooltip_text_lab_test,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_msg_notes,
                     l_tooltip_title_notes_tech,
                     l_tooltip_text_notes_tech,
                     l_tooltip_title_notes_pat,
                     l_tooltip_text_notes_pat,
                     l_tooltip_title_lab_test,
                     l_tooltip_text_lab_test,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        g_error := 'PK_PROCEDURES_EXTERNAL_API_DB.GET_ORDERED_LIST / ' || l_params;
        IF pk_procedures_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_patient      => i_id_patient,
                                                          i_episode      => i_episode,
                                                          i_viewer_area  => i_viewer_area,
                                                          o_ordered_list => l_list,
                                                          o_error        => o_error)
        
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_count,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        g_error := 'PK_BP_EXTERNAL_API_DB.GET_ORDERED_LIST / ' || l_params;
        IF pk_bp_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_id_patient,
                                                  i_episode      => i_episode,
                                                  i_viewer_area  => i_viewer_area,
                                                  o_ordered_list => l_list,
                                                  o_error        => o_error)
        
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_count,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        --------------------------------------------------------------------------------
        g_error := 'PK_RT_MED_PFH.GET_MCDT_ORDERED_LIST / ' || l_params;
        IF pk_rt_med_pfh.get_mcdt_ordered_list(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_patient   => i_id_patient,
                                               i_viewer_area  => i_viewer_area,
                                               i_id_episode   => i_episode,
                                               o_ordered_list => l_list,
                                               o_error        => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_code_title,
                         l_dt_req_tstz,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_instr_bg_color,
                         l_instr_bg_alpha,
                         l_dt_req,
                         l_task_title,
                         l_tooltip_title_lab_test,
                         l_tooltip_text_lab_test;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     title,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     instr_bg_color,
                     instr_bg_alpha,
                     dt_req,
                     task_title,
                     tooltip_title_lab_test,
                     tooltip_text_lab_test)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_code_title,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_instr_bg_color,
                     l_instr_bg_alpha,
                     l_dt_req,
                     l_task_title,
                     l_tooltip_title_lab_test,
                     l_tooltip_text_lab_test);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        -- CONSULTS : OPINION
        --------------------------------------------------------------------------------
    
        g_error := 'pk_rehab_external_api_db.get_ordered_list / ' || l_params;
        IF pk_rehab_external_api_db.get_ordered_list(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_patient      => i_id_patient,
                                                     i_viewer_area  => i_viewer_area,
                                                     i_episode      => i_episode,
                                                     o_ordered_list => l_list,
                                                     o_error        => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         --l_code_title,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_desc_status,
                         l_flg_type,
                         l_desc,
                         l_rank,
                         l_rank_order,
                         l_num_count;
            
                EXIT WHEN l_list%NOTFOUND;
                l_code_title     := NULL;
                l_instr_bg_color := NULL;
                l_instr_bg_alpha := NULL;
                l_icon_skinning  := NULL;
                l_task_title     := NULL;
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     title,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     instr_bg_color,
                     instr_bg_alpha,
                     icon_skinning,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_code_title,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_instr_bg_color,
                     l_instr_bg_alpha,
                     l_icon_skinning,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
        -- *********************** REHAB *************************
    
        g_error := 'pk_comm_orders_db.get_comm_order_viewer_list / ' || l_params;
        IF pk_comm_orders_db.get_comm_order_viewer_list(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_patient     => i_id_patient,
                                                        i_viewer_area => i_viewer_area,
                                                        i_episode     => i_episode,
                                                        o_list        => l_list,
                                                        o_error       => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_code_title,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_instr_bg_color,
                         l_instr_bg_alpha,
                         l_icon_skinning,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     title,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     instr_bg_color,
                     instr_bg_alpha,
                     icon_skinning,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_code_title,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_instr_bg_color,
                     l_instr_bg_alpha,
                     l_icon_skinning,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        g_error := 'OPEN o_list FOR / ' || l_params;
    
        g_error := 'PK_OPINION.GET_ORDERED_LIST_OPINION';
        IF pk_opinion.get_ordered_list_opinion(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_id_patient,
                                               i_viewer_area  => i_viewer_area,
                                               i_episode      => i_episode,
                                               o_ordered_list => l_list,
                                               o_error        => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_code_title,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_count,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     title,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_code_title,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        g_error := 'pk_prog_notes_grids.get_ordered_list';
        IF pk_prog_notes_grids.get_ordered_list(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_patient      => i_id_patient,
                                                i_viewer_area  => i_viewer_area,
                                                i_episode      => i_episode,
                                                o_ordered_list => l_list,
                                                o_error        => o_error)
        THEN
            LOOP
                FETCH l_list
                    INTO l_id,
                         l_code_description,
                         l_description,
                         l_code_title,
                         l_dt_req_tstz,
                         l_dt_req,
                         l_flg_status,
                         l_flg_type,
                         l_desc_status,
                         l_rank,
                         l_rank_order,
                         l_count,
                         l_task_title;
            
                EXIT WHEN l_list%NOTFOUND;
            
                INSERT INTO gen_mcdt_rank_tmp
                    (id_execution,
                     id,
                     code_description,
                     description,
                     title,
                     dt_req_tstz,
                     flg_status,
                     flg_type,
                     desc_status,
                     rank,
                     rank_order,
                     dt_req,
                     task_title)
                VALUES
                    (l_id_execution,
                     l_id,
                     l_code_description,
                     l_description,
                     l_code_title,
                     l_dt_req_tstz,
                     l_flg_status,
                     l_flg_type,
                     l_desc_status,
                     l_rank,
                     l_rank_order,
                     l_dt_req,
                     l_task_title);
            
            END LOOP;
        ELSE
            RAISE invoking_external_prc_error;
        END IF;
    
        OPEN o_list FOR
            SELECT gmrt.id,
                   gmrt.code_description,
                   gmrt.description,
                   gmrt.title,
                   gmrt.dt_req_tstz,
                   gmrt.dt_req,
                   gmrt.flg_status,
                   gmrt.flg_type,
                   gmrt.desc_status,
                   gmrt.rank,
                   gmrt.rank_order,
                   gmrt.tooltip_title_notes_tech,
                   gmrt.tooltip_text_notes_tech,
                   gmrt.tooltip_title_notes_pat,
                   gmrt.tooltip_text_notes_pat,
                   gmrt.tooltip_title_lab_test,
                   gmrt.tooltip_text_lab_test,
                   gmrt.msg_notes,
                   gmrt.instr_bg_color,
                   gmrt.instr_bg_alpha,
                   gmrt.icon_skinning,
                   gmrt.task_title
              FROM gen_mcdt_rank_tmp gmrt
             WHERE gmrt.id_execution = l_id_execution
             ORDER BY gmrt.rank ASC, gmrt.rank_order ASC, gmrt.id DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN invoking_external_prc_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_MCDT',
                                              'GET_ORDERED_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_ordered_list;

    FUNCTION get_codification_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_mcdt_type IN p1_external_request.flg_type%TYPE,
        i_flg_type  IN VARCHAR2,
        i_flg_p1    IN VARCHAR2 DEFAULT 'N',
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cfg_mcdt_filter_ref_ext VARCHAR2(20 CHAR) := pk_sysconfig.get_config(i_code_cf => 'MCDT_FILTER_REF_EXT',
                                                                               i_prof    => i_prof);
    
    BEGIN
    
        g_error := 'GET CURSOR o_list';
        -- Open output Cursor 
        IF i_mcdt_type = pk_ref_constant.g_p1_type_a
        THEN
            -- Analysis
            OPEN o_list FOR
                SELECT DISTINCT c.id_codification,
                                pk_translation.get_translation(i_lang, c.code_codification) desc_codification,
                                cis.flg_default
                  FROM codification c, codification_instit_soft cis
                 WHERE c.flg_available = pk_alert_constant.g_available
                   AND c.id_codification = cis.id_codification
                   AND cis.id_institution = i_prof.institution
                   AND cis.id_software = i_prof.software
                   AND cis.flg_available = pk_alert_constant.g_available
                   AND EXISTS
                 (SELECT 1
                          FROM analysis_codification ac,
                               (SELECT id_analysis, id_sample_type
                                  FROM analysis_instit_soft
                                 WHERE flg_type = pk_lab_tests_constant.g_analysis_can_req
                                   AND id_software = i_prof.software
                                   AND id_institution = i_prof.institution
                                   AND flg_available = pk_lab_tests_constant.g_available) ais
                         WHERE cis.id_codification = ac.id_codification
                           AND ac.flg_available = pk_lab_tests_constant.g_available
                           AND ac.id_analysis = ais.id_analysis
                           AND ac.id_sample_type = ais.id_sample_type)
                   AND (l_cfg_mcdt_filter_ref_ext = '-1' OR c.id_content = l_cfg_mcdt_filter_ref_ext)
                   AND ((i_flg_p1 = pk_alert_constant.g_yes AND cis.flg_use_on_referral = pk_alert_constant.g_yes) OR
                       i_flg_p1 = pk_alert_constant.g_no)
                 ORDER BY desc_codification;
        
        ELSIF i_mcdt_type = pk_ref_constant.g_p1_type_e
              OR i_mcdt_type = pk_ref_constant.g_p1_type_i
        THEN
            -- Exams and Imaging
            OPEN o_list FOR
                SELECT DISTINCT c.id_codification,
                                pk_translation.get_translation(i_lang, c.code_codification) desc_codification,
                                cis.flg_default
                  FROM codification c, codification_instit_soft cis
                 WHERE c.flg_available = pk_alert_constant.g_available
                   AND c.id_codification = cis.id_codification
                   AND cis.id_institution = i_prof.institution
                   AND cis.id_software = i_prof.software
                   AND cis.flg_available = pk_alert_constant.g_available
                   AND EXISTS
                 (SELECT 1
                          FROM exam_codification ec,
                               (SELECT e.id_exam
                                  FROM exam e, exam_dep_clin_serv edcs
                                 WHERE e.flg_type = i_mcdt_type
                                   AND e.flg_available = pk_exam_constant.g_available
                                   AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                   AND edcs.id_software = i_prof.software
                                   AND edcs.id_institution = i_prof.institution) edcs
                         WHERE cis.id_codification = ec.id_codification
                           AND ec.flg_available = pk_exam_constant.g_available
                           AND ec.id_exam = edcs.id_exam)
                   AND (l_cfg_mcdt_filter_ref_ext = '-1' OR c.id_content = l_cfg_mcdt_filter_ref_ext)
                   AND ((i_flg_p1 = pk_alert_constant.g_yes AND cis.flg_use_on_referral = pk_alert_constant.g_yes) OR
                       i_flg_p1 = pk_alert_constant.g_no)
                 ORDER BY desc_codification;
        
        ELSIF i_mcdt_type = pk_ref_constant.g_p1_type_p
        THEN
            -- Procedures
            OPEN o_list FOR
                SELECT DISTINCT c.id_codification,
                                pk_translation.get_translation(i_lang, c.code_codification) desc_codification,
                                cis.flg_default
                  FROM codification c, codification_instit_soft cis
                 WHERE c.flg_available = pk_alert_constant.g_available
                   AND cis.id_codification = c.id_codification
                   AND cis.id_institution = i_prof.institution
                   AND cis.id_software = i_prof.software
                   AND cis.flg_available = pk_alert_constant.g_available
                   AND EXISTS
                 (SELECT 1
                          FROM interv_codification ic,
                               (SELECT i.id_intervention
                                  FROM intervention i, interv_dep_clin_serv idcs
                                 WHERE i.flg_status = pk_procedures_constant.g_active
                                   AND i.flg_type != pk_procedures_constant.g_type_interv_surgical
                                   AND i.id_intervention = idcs.id_intervention
                                   AND idcs.flg_type = pk_procedures_constant.g_interv_can_req
                                   AND idcs.id_software = i_prof.software
                                   AND idcs.id_institution = i_prof.institution) idcs
                         WHERE cis.id_codification = ic.id_codification
                           AND ic.flg_available = pk_procedures_constant.g_available
                           AND ic.id_intervention = idcs.id_intervention)
                   AND (l_cfg_mcdt_filter_ref_ext = '-1' OR c.id_content = l_cfg_mcdt_filter_ref_ext)
                   AND ((i_flg_p1 = pk_alert_constant.g_yes AND cis.flg_use_on_referral = pk_alert_constant.g_yes) OR
                       i_flg_p1 = pk_alert_constant.g_no)
                 ORDER BY desc_codification;
        
        ELSIF i_mcdt_type = pk_ref_constant.g_p1_type_f
        THEN
            -- Rehabilitation
            OPEN o_list FOR
                SELECT DISTINCT ic.id_codification,
                                pk_translation.get_translation(i_lang, c.code_codification) desc_codification,
                                cis.flg_default
                  FROM interv_codification ic
                  JOIN codification c
                    ON c.id_codification = ic.id_codification
                  JOIN codification_instit_soft cis
                    ON cis.id_codification = ic.id_codification
                  JOIN rehab_area_interv rai
                    ON rai.id_intervention = ic.id_intervention
                  JOIN rehab_area_inst ra
                    ON ra.id_rehab_area = rai.id_rehab_area
                 WHERE ic.flg_available = pk_alert_constant.g_available
                   AND c.flg_available = pk_alert_constant.g_available
                   AND cis.id_institution = i_prof.institution
                   AND cis.id_software = i_prof.software
                   AND cis.flg_available = pk_alert_constant.g_available
                   AND ra.id_institution IN (0, i_prof.institution)
                   AND (l_cfg_mcdt_filter_ref_ext = '-1' OR c.id_content = l_cfg_mcdt_filter_ref_ext)
                   AND ((i_flg_p1 = pk_alert_constant.g_yes AND cis.flg_use_on_referral = pk_alert_constant.g_yes) OR
                       i_flg_p1 = pk_alert_constant.g_no)
                 ORDER BY desc_codification;
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
                                              'GET_CODIFICATION_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_codification_list;

    FUNCTION check_prof_cancel_permissions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_sys_button IN table_number
    ) RETURN VARCHAR2 IS
    
        l_summ_flg_cancel NUMBER := 0;
    BEGIN
        SELECT SUM(decode(flg_cancel, pk_alert_constant.g_active, 1, 0))
          INTO l_summ_flg_cancel
          FROM (SELECT pta.flg_cancel
                  FROM sys_button sb, sys_button_prop sbp, profile_templ_access pta, profile_template pt
                 WHERE sb.id_sys_button = sbp.id_sys_button
                   AND sbp.id_sys_button_prop = pta.id_sys_button_prop
                   AND sbp.flg_visible = pk_access.g_sbs_visible
                   AND sb.id_sys_button IN (SELECT /*+ cardinality(t 1) */
                                             *
                                              FROM TABLE(i_id_sys_button) t)
                   AND pt.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof)
                      -- adds
                   AND pta.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                   AND pta.flg_add_remove = pk_access.g_flg_type_add -- add
                      -- removes (including exceptions)
                   AND NOT EXISTS (SELECT 1
                          FROM profile_templ_access_exception ptae
                         WHERE ptae.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                           AND ptae.id_sys_button_prop = pta.id_sys_button_prop
                           AND ptae.flg_type = pk_access.g_flg_type_remove
                           AND ptae.id_software IN (i_prof.software, 0)
                           AND ptae.id_institution IN (i_prof.institution, 0))
                   AND NOT EXISTS (SELECT 1
                          FROM profile_templ_access pt_access
                         WHERE pt_access.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                           AND pt_access.id_sys_button_prop = pta.id_sys_button_prop
                           AND pt_access.flg_add_remove = pk_access.g_flg_type_remove)
                -- Add exceptions
                UNION ALL
                SELECT ptae.flg_cancel
                  FROM sys_button sb, sys_button_prop sbp, profile_templ_access_exception ptae, profile_template pt
                 WHERE sb.id_sys_button = sbp.id_sys_button
                   AND sbp.id_sys_button_prop = ptae.id_sys_button_prop
                   AND sbp.flg_visible = pk_access.g_sbs_visible
                   AND sb.id_sys_button IN (SELECT /*+ cardinality(t 1) */
                                             *
                                              FROM TABLE(i_id_sys_button) t)
                   AND pt.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof)
                   AND ptae.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                   AND ptae.flg_type = pk_access.g_flg_type_add
                   AND ptae.id_software IN (i_prof.software, 0)
                   AND ptae.id_institution IN (i_prof.institution, 0));
    
        IF (l_summ_flg_cancel > 0)
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    END check_prof_cancel_permissions;

    /********************************************************************************************
    * Gets the selected code dep_clin_serv of a given professional when he made a record
    *
    * @param   I_PROF professional, institution and software ids        
    * @param   I_DT_REG                   record date
    * @param   I_EPISODE                  episode ID        
    *
    * @RETURN  professional dep_clin_serv (CODE)
    * @author  Teresa Coutinho
    * @version 1.0
    * @since   06/03/2012
    *
    **********************************************************************************************/
    FUNCTION get_reg_prof_dcs
    (
        i_prof_id IN professional.id_professional%TYPE,
        i_dt_reg  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_spec   VARCHAR2(200);
        l_dt_reg TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_epis_prof_dcs IS
            SELECT (SELECT cs.code_clinical_service
                      FROM clinical_service cs
                     WHERE cs.id_clinical_service = dcs.id_clinical_service)
              FROM dep_clin_serv dcs
              JOIN epis_prof_dcs edcs
                ON edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
             WHERE edcs.id_professional = i_prof_id
               AND edcs.id_episode = i_episode
               AND edcs.dt_reg < l_dt_reg
             ORDER BY edcs.dt_reg DESC;
    
    BEGIN
    
        -- remove small differences
        l_dt_reg := i_dt_reg + numtodsinterval(4, 'SECOND');
    
        OPEN c_epis_prof_dcs;
        FETCH c_epis_prof_dcs
            INTO l_spec;
        CLOSE c_epis_prof_dcs;
    
        RETURN l_spec;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_reg_prof_dcs;

    FUNCTION get_mcdt_body_struct
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_task     IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_task1 NUMBER;
        l_task2 NUMBER;
    
    BEGIN
    
        IF i_flg_type = 'A'
        THEN
            l_task1 := to_number(substr(i_task, 0, instr(i_task, '|') - 1));
            l_task2 := to_number(REPLACE(i_task, substr(i_task, 0, instr(i_task, '|'))));
        
            g_error := 'OPEN O_LIST';
            OPEN o_list FOR
                SELECT abs.id_analysis id_task, abs.id_body_structure, 'U' flg_main_laterality, bs.id_mcs_concept
                  FROM analysis_body_structure abs
                  LEFT JOIN body_structure bs
                    ON (bs.id_body_structure = abs.id_body_structure)
                 WHERE abs.id_analysis = l_task1
                   AND abs.id_sample_type = l_task2
                   AND abs.flg_available = pk_alert_constant.g_yes;
        
        ELSIF i_flg_type IN ('E', 'EI', 'EO')
        THEN
            l_task1 := to_number(i_task);
        
            g_error := 'OPEN O_LIST';
            OPEN o_list FOR
                SELECT e.id_exam id_task, ebs.id_body_structure, ebs.flg_main_laterality, bs.id_mcs_concept
                  FROM exam e
                  JOIN exam_body_structure ebs
                    ON (e.id_exam = ebs.id_exam)
                  LEFT JOIN body_structure bs
                    ON (bs.id_body_structure = ebs.id_body_structure)
                 WHERE e.id_exam = l_task1
                   AND ebs.flg_available = pk_alert_constant.g_yes;
        
        ELSIF i_flg_type = 'I'
        THEN
            l_task1 := to_number(i_task);
        
            g_error := 'OPEN O_LIST';
            OPEN o_list FOR
                SELECT i.id_intervention id_task, ibs.id_body_structure, ibs.flg_main_laterality, bs.id_mcs_concept
                  FROM intervention i
                  JOIN interv_body_structure ibs
                    ON (i.id_intervention = ibs.id_intervention)
                  LEFT JOIN body_structure bs
                    ON (bs.id_body_structure = ibs.id_body_structure)
                 WHERE i.id_intervention = l_task1
                   AND ibs.flg_available = pk_alert_constant.g_yes;
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
                                              'GET_MCDT_BODY_STRUCT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_mcdt_body_struct;

    FUNCTION get_mcdt_laterality
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_task     IN VARCHAR2,
        o_list     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        -------- get_mcdt_body_struct--------------
        l_list_bs         pk_types.cursor_type;
        l_task            table_varchar;
        l_body_structure  table_varchar;
        l_main_laterality table_varchar;
        l_mcs_concept     table_varchar;
        -------------------------------------------
        l_mcs_concept_aux table_varchar := table_varchar();
        l_lat_array       table_varchar := table_varchar();
        l_lat             VARCHAR2(4000 CHAR);
        -------------------------------------------        
        l_all_main_lat_empty  VARCHAR2(1 CHAR);
        l_some_main_lat_empty VARCHAR2(1 CHAR);
        l_aux_empty_lat       VARCHAR2(1 CHAR);
        l_aux_nempty_lat      VARCHAR2(1 CHAR);
    BEGIN
        g_error  := 'Call get_mcdt_body_struct / I_FLG_TYPE= ' || i_flg_type || ' i_task= ' || i_task;
        g_retval := pk_mcdt.get_mcdt_body_struct(i_lang     => i_lang,
                                                 i_prof     => i_prof,
                                                 i_flg_type => i_flg_type,
                                                 i_task     => i_task,
                                                 o_list     => l_list_bs,
                                                 o_error    => o_error);
    
        IF g_retval
        THEN
            g_error := 'FETCH l_list BULK COLLECT';
            FETCH l_list_bs BULK COLLECT
                INTO l_task, l_body_structure, l_main_laterality, l_mcs_concept;
            CLOSE l_list_bs;
        
            -- More than 1 body_structure
            IF l_body_structure.count > 1
            THEN
            
                l_all_main_lat_empty  := pk_alert_constant.g_yes;
                l_some_main_lat_empty := pk_alert_constant.g_no;
            
                <<loop_main_lat>>
                FOR i IN 1 .. l_main_laterality.count
                LOOP
                    IF l_main_laterality(i) IS NULL
                    THEN
                        l_mcs_concept_aux.extend(1);
                        l_mcs_concept_aux(l_mcs_concept_aux.count) := l_mcs_concept(i);
                        l_some_main_lat_empty := pk_alert_constant.g_yes;
                    ELSE
                        l_all_main_lat_empty := pk_alert_constant.g_no;
                    END IF;
                END LOOP;
                -- flg_main_laterality is empty for all records
                IF l_all_main_lat_empty = pk_alert_constant.get_yes
                THEN
                    l_aux_empty_lat  := pk_alert_constant.get_no;
                    l_aux_nempty_lat := pk_alert_constant.get_no;
                
                    FOR i IN 1 .. l_mcs_concept.count
                    LOOP
                        g_error := 'Call pk_mcs.get_concept_laterality/ I_SOURCE=1, I_CONCEPT=' || l_mcs_concept(i);
                        l_lat   := pk_mcs.get_concept_laterality(i_source => 1, i_concept => l_mcs_concept(i));
                        IF l_lat IS NULL
                        THEN
                            l_aux_empty_lat := pk_alert_constant.get_yes;
                        ELSE
                            l_aux_nempty_lat := pk_alert_constant.get_yes;
                        END IF;
                    END LOOP;
                
                    IF l_aux_empty_lat = pk_alert_constant.get_no -- All with laterality
                    THEN
                        o_list := g_mcdt_lat_any; -- Any laterality
                        RETURN TRUE;
                    ELSIF l_aux_empty_lat = pk_alert_constant.get_yes
                          AND l_aux_nempty_lat = pk_alert_constant.get_yes -- Some with laterality
                    THEN
                        o_list := g_mcdt_lat_all; -- All Options
                        RETURN TRUE;
                    ELSIF l_aux_empty_lat = pk_alert_constant.get_yes
                          AND l_aux_nempty_lat = pk_alert_constant.get_no -- None with laterality
                    THEN
                        o_list := g_mcdt_lat_na; -- Not aplicable
                        RETURN TRUE;
                    END IF;
                
                ELSE
                    -- if flg_main_laterality not null  for all mcdt/task
                    IF l_some_main_lat_empty = pk_alert_constant.g_yes
                       AND l_all_main_lat_empty = pk_alert_constant.get_no
                       AND l_mcs_concept_aux.exists(1)
                    THEN
                        <<loop_mcs_concept>>
                        FOR i IN 1 .. l_mcs_concept_aux.count
                        LOOP
                            l_lat_array.extend;
                            g_error := 'Call pk_mcs.get_concept_laterality/ I_SOURCE=1, I_CONCEPT=' ||
                                       l_mcs_concept_aux(i);
                            IF pk_mcs.get_concept_laterality(i_source => 1, i_concept => l_mcs_concept_aux(i)) IS NULL
                            THEN
                                l_lat_array(i) := g_mcdt_lat_na; -- Not aplicable
                            ELSE
                                l_lat_array(i) := g_mcdt_lat_any; -- Any laterality
                            END IF;
                        END LOOP;
                    
                        <<loop_lat>>
                        l_lat := l_lat_array(1);
                        FOR i IN 1 .. l_lat_array.count
                        LOOP
                            IF l_lat != l_lat_array(1)
                            THEN
                                o_list := g_mcdt_lat_all; -- All Options
                                RETURN TRUE;
                            END IF;
                        END LOOP;
                    
                        o_list := l_lat;
                        RETURN TRUE;
                    
                    ELSIF l_some_main_lat_empty = pk_alert_constant.get_no
                          AND l_all_main_lat_empty = pk_alert_constant.get_no
                    THEN
                        l_lat := l_main_laterality(1);
                        FOR i IN 1 .. l_main_laterality.count
                        LOOP
                            --
                            IF l_lat != l_main_laterality(1)
                            THEN
                                o_list := g_mcdt_lat_all; -- All Options
                                RETURN TRUE;
                            END IF;
                        END LOOP;
                        o_list := l_lat;
                        RETURN TRUE;
                    END IF;
                END IF;
            
                /* ELSIF NOT l_body_structure.exists(1)
                      AND NOT l_main_laterality.exists(1)
                THEN
                    o_list := g_mcdt_lat_all; -- All Options
                    RETURN TRUE;*/
            ELSE
                --  1  body_structure
                IF l_main_laterality.exists(1)
                THEN
                    IF l_main_laterality(1) IS NOT NULL
                    THEN
                        o_list := l_main_laterality(1);
                        RETURN TRUE;
                    ELSE
                        IF l_mcs_concept(1) = 0
                        THEN
                            o_list := g_mcdt_lat_na; -- Not aplicable 
                            RETURN TRUE;
                        ELSE
                            -- TODO 1 Should be sys_config
                            g_error := 'Call pk_mcs.get_concept_lateralityt / I_SOURCE= ' || 1 || ' i_concept= ' ||
                                       l_mcs_concept(1);
                            l_lat   := pk_mcs.get_concept_laterality(i_source => 1, i_concept => l_mcs_concept(1));
                            IF l_lat IS NULL
                            THEN
                                o_list := g_mcdt_lat_na; -- Not aplicable
                                RETURN TRUE;
                            ELSE
                                o_list := g_mcdt_lat_any; -- Any laterality
                                RETURN TRUE;
                            END IF;
                        END IF;
                    END IF;
                ELSE
                    o_list := g_mcdt_lat_all; -- All Options
                    RETURN TRUE;
                END IF;
            END IF;
        END IF;
    
        o_list := g_mcdt_lat_all; -- All Options
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MCDT_LATERALITY',
                                              o_error);
            RETURN FALSE;
    END get_mcdt_laterality;

    FUNCTION check_mcdt_laterality
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_task     IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_var   VARCHAR2(4000);
        l_error t_error_out;
    
    BEGIN
    
        g_error  := 'Call get_mcdt_laterality \ I_FLG_TYPE= ' || i_flg_type || ' I_TASK=' || i_task;
        g_retval := get_mcdt_laterality(i_lang     => i_lang,
                                        i_prof     => i_prof,
                                        i_flg_type => i_flg_type,
                                        i_task     => i_task,
                                        o_list     => l_var,
                                        o_error    => l_error);
    
        RETURN l_var;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_MCDT_LATERALITY',
                                              l_error);
            RETURN NULL;
    END check_mcdt_laterality;

    /**
    * Returns a list of laterality options to be selected
    *
    * @param   i_lang             Language associated to the professional executing the request
    * @param   i_prof             Professional, institution and software ids
    * @param   i_flg_laterality   Laterality flag
    * @param   o_list             Cursor with laterality options available
    * @param   o_error            An error message, set when return=false
    *    
    * @return    TRUE if sucess, FALSE otherwise
    *
    * @author    Ana Monteiro
    * @version   2.5
    * @since     19-08-2011
    */
    FUNCTION get_laterality
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_laterality IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list pk_types.cursor_type;
    
        l_desc_tab table_varchar;
        l_val_tab  table_varchar;
        l_img_tab  table_varchar;
        l_rank_tab table_varchar;
    
    BEGIN
        g_error := 'Init get_laterality / i_flg_laterality=' || i_flg_laterality;
        pk_alertlog.log_init(g_error);
    
        IF NOT pk_sysdomain.get_values_domain(i_code_dom      => 'FLG_LATERALITY_' || i_flg_laterality,
                                              i_lang          => i_lang,
                                              i_vals_included => NULL,
                                              i_vals_excluded => NULL,
                                              o_error         => o_error,
                                              o_data          => l_list)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'FETCH l_list BULK COLLECT';
        FETCH l_list BULK COLLECT
            INTO l_desc_tab, l_val_tab, l_img_tab, l_rank_tab;
        CLOSE l_list;
    
        g_error := 'OPEN o_list FOR';
        OPEN o_list FOR
            SELECT desc_laterality, flg_laterality
              FROM (SELECT t_desc.column_value desc_laterality, t_val.column_value flg_laterality
                      FROM (SELECT rownum rn, column_value
                              FROM TABLE(l_desc_tab)) t_desc -- desc
                      JOIN (SELECT rownum rn, column_value
                             FROM TABLE(l_val_tab)) t_val -- val
                        ON (t_desc.rn = t_val.rn))
             ORDER BY desc_laterality;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LATERALITY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_laterality;

    /**
    * Returns a list of laterality options to be selected
    *
    * @param   i_lang                      Language associated to the professional executing the request
    * @param   i_prof                      Professional, institution and software ids
    * @param   i_flg_laterality_mcdt       Laterality flags
    * @param   o_list                      Cursor with laterality options available
    * @param   o_error                     An error message, set when return=false
    *    
    * @return    TRUE if sucess, FALSE otherwise
    *
    * @author    Ana Monteiro
    * @version   2.5
    * @since     19-08-2011
    */
    FUNCTION get_laterality
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_laterality_mcdt IN table_varchar,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc_tab       table_varchar;
        l_val_tab        table_varchar;
        l_img_tab        table_varchar;
        l_rank_tab       table_varchar;
        l_laterality_tab table_varchar := table_varchar();
    
        l_desc_final_tab       table_varchar := table_varchar();
        l_val_final_tab        table_varchar := table_varchar();
        l_laterality_final_tab table_varchar := table_varchar();
    
        l_flg_laterality_mcdt table_varchar;
    BEGIN
    
        g_error  := 'Call pk_mcdt.get_laterality_all / I_FLG_TYPE =' || 'I';
        g_retval := pk_mcdt.get_laterality_all(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_flg_laterality_mcdt => i_flg_laterality_mcdt,
                                               i_flg_type            => 'I',
                                               o_list                => o_list,
                                               o_error               => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LATERALITY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_laterality;

    FUNCTION get_laterality_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_laterality_mcdt IN table_varchar,
        i_flg_type            IN VARCHAR2,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_list pk_types.cursor_type;
    
        l_desc_tab       table_varchar;
        l_val_tab        table_varchar;
        l_img_tab        table_varchar;
        l_rank_tab       table_varchar;
        l_laterality_tab table_varchar := table_varchar();
    
        l_desc_final_tab       table_varchar := table_varchar();
        l_val_final_tab        table_varchar := table_varchar();
        l_laterality_final_tab table_varchar := table_varchar();
    
        l_flg_laterality_mcdt table_varchar;
    BEGIN
        g_error := 'Init get_laterality';
        pk_alertlog.log_init(g_error);
    
        SELECT DISTINCT column_value
          BULK COLLECT
          INTO l_flg_laterality_mcdt
          FROM TABLE(CAST(i_flg_laterality_mcdt AS table_varchar));
    
        g_error := 'FOR i IN 1 .. ' || l_flg_laterality_mcdt.count;
        FOR i IN 1 .. l_flg_laterality_mcdt.count
        LOOP
            IF NOT pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_code_dom      => 'FLG_LATERALITY_' || l_flg_laterality_mcdt(i),
                                                  i_dep_clin_serv => NULL,
                                                  o_data_mkt      => l_list,
                                                  o_error         => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'FETCH l_list BULK COLLECT';
            FETCH l_list BULK COLLECT
                INTO l_desc_tab, l_val_tab, l_img_tab, l_rank_tab;
            CLOSE l_list;
        
            IF i_flg_type = 'I'
            THEN
            
                IF i = 1
                THEN
                    g_error          := 'arrays';
                    l_desc_final_tab := l_desc_tab;
                    l_val_final_tab  := l_val_tab;
                ELSE
                    g_error          := 'arrays';
                    l_desc_final_tab := l_desc_final_tab MULTISET INTERSECT DISTINCT l_desc_tab;
                    l_val_final_tab  := l_val_final_tab MULTISET INTERSECT DISTINCT l_val_tab;
                END IF;
            ELSIF i_flg_type = 'U'
            THEN
                l_desc_final_tab := l_desc_final_tab MULTISET UNION l_desc_tab;
                l_val_final_tab  := l_val_final_tab MULTISET UNION l_val_tab;
            END IF;
            l_laterality_tab := table_varchar();
            l_laterality_tab.extend(l_val_tab.count);
        
            FOR j IN 1 .. l_val_tab.count
            LOOP
                l_laterality_tab(j) := l_flg_laterality_mcdt(i);
            END LOOP;
        
            l_laterality_final_tab := l_laterality_final_tab MULTISET UNION l_laterality_tab;
        
        END LOOP;
    
        g_error := 'OPEN o_list FOR';
        OPEN o_list FOR
            SELECT t_desc.column_value desc_laterality,
                   t_val.column_value  flg_laterality,
                   t_lat.column_value  flg_laterality_mcdt
              FROM (SELECT rownum rn, column_value
                      FROM TABLE(l_desc_final_tab)) t_desc -- desc
              JOIN (SELECT rownum rn, column_value
                      FROM TABLE(l_val_final_tab)) t_val -- val
                ON (t_desc.rn = t_val.rn)
              JOIN (SELECT rownum rn, column_value
                      FROM TABLE(l_laterality_final_tab)) t_lat -- laterality_mcdt
                ON (t_desc.rn = t_lat.rn)
             ORDER BY flg_laterality_mcdt, desc_laterality;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LATERALITY_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_laterality_all;

    FUNCTION get_laterality_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN VARCHAR2,
        i_mcdt_type IN p1_external_request.flg_type%TYPE,
        i_mcdt      IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_list pk_types.cursor_type;
    
        l_desc_tab       table_varchar;
        l_val_tab        table_varchar;
        l_img_tab        table_varchar;
        l_rank_tab       table_varchar;
        l_laterality_tab table_varchar := table_varchar();
    
        l_desc_final_tab       table_varchar := table_varchar();
        l_val_final_tab        table_varchar := table_varchar();
        l_laterality_final_tab table_varchar := table_varchar();
    
        -- l_flg_laterality_mcdt table_varchar;
    
        l_ret                         t_tbl_core_domain;
        l_tbl_mcdt                    table_number;
        l_tbl_flg_laterality_mcdt     table_varchar := table_varchar();
        l_tbl_flg_laterality_mcdt_aux table_varchar;
        l_error                       t_error_out;
    BEGIN
        g_error := 'Init get_laterality';
        pk_alertlog.log_init(g_error);
    
        IF i_mcdt_type = 'P'
        THEN
        
            l_tbl_mcdt := pk_utils.str_split_n(i_list => i_mcdt, i_delim => '|');
        
            FOR i IN l_tbl_mcdt.first .. l_tbl_mcdt.last
            LOOP
                SELECT DISTINCT ibs.flg_main_laterality
                  BULK COLLECT
                  INTO l_tbl_flg_laterality_mcdt_aux
                  FROM interv_body_structure ibs
                 WHERE ibs.id_intervention = l_tbl_mcdt(i)
                   AND ibs.flg_available = pk_alert_constant.g_yes;
            
                IF l_tbl_flg_laterality_mcdt_aux.count > 0
                THEN
                    IF l_tbl_flg_laterality_mcdt.count = 0
                    THEN
                        l_tbl_flg_laterality_mcdt := l_tbl_flg_laterality_mcdt_aux;
                    ELSE
                        l_tbl_flg_laterality_mcdt := l_tbl_flg_laterality_mcdt MULTISET INTERSECT
                                                     l_tbl_flg_laterality_mcdt_aux;
                    END IF;
                ELSE
                    IF l_tbl_flg_laterality_mcdt.count = 0
                    THEN
                        l_tbl_flg_laterality_mcdt := table_varchar('B', 'L', 'N', 'R');
                    ELSE
                        l_tbl_flg_laterality_mcdt := l_tbl_flg_laterality_mcdt MULTISET INTERSECT
                                                     table_varchar('B', 'L', 'N', 'R');
                    END IF;
                END IF;
            
            END LOOP;
        ELSIF i_mcdt_type = 'E'
        THEN
            l_tbl_mcdt := pk_utils.str_split_n(i_list => i_mcdt, i_delim => '|');
        
            FOR i IN l_tbl_mcdt.first .. l_tbl_mcdt.last
            LOOP
                SELECT DISTINCT eis.flg_main_laterality
                  BULK COLLECT
                  INTO l_tbl_flg_laterality_mcdt_aux
                  FROM exam_body_structure eis
                 WHERE eis.id_exam = l_tbl_mcdt(i)
                   AND eis.flg_available = pk_alert_constant.g_yes;
            
                IF l_tbl_flg_laterality_mcdt_aux.count > 0
                THEN
                    IF l_tbl_flg_laterality_mcdt.count = 0
                    THEN
                        l_tbl_flg_laterality_mcdt := l_tbl_flg_laterality_mcdt_aux;
                    ELSE
                        l_tbl_flg_laterality_mcdt := l_tbl_flg_laterality_mcdt MULTISET INTERSECT
                                                     l_tbl_flg_laterality_mcdt_aux;
                    END IF;
                ELSE
                    IF l_tbl_flg_laterality_mcdt.count = 0
                    THEN
                        l_tbl_flg_laterality_mcdt := table_varchar('B', 'L', 'N', 'R');
                    ELSE
                        l_tbl_flg_laterality_mcdt := l_tbl_flg_laterality_mcdt MULTISET INTERSECT
                                                     table_varchar('B', 'L', 'N', 'R');
                    END IF;
                END IF;
            
            END LOOP;
        END IF;
    
        g_error := 'FOR i IN 1 .. ' || l_tbl_flg_laterality_mcdt.count;
        FOR i IN 1 .. l_tbl_flg_laterality_mcdt.count
        LOOP
            IF NOT pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_code_dom      => 'FLG_LATERALITY_' || l_tbl_flg_laterality_mcdt(i),
                                                  i_dep_clin_serv => NULL,
                                                  o_data_mkt      => l_list,
                                                  o_error         => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'FETCH l_list BULK COLLECT';
            FETCH l_list BULK COLLECT
                INTO l_desc_tab, l_val_tab, l_img_tab, l_rank_tab;
            CLOSE l_list;
        
            IF i_flg_type = 'I'
            THEN
            
                IF i = 1
                THEN
                    g_error          := 'arrays';
                    l_desc_final_tab := l_desc_tab;
                    l_val_final_tab  := l_val_tab;
                ELSE
                    g_error          := 'arrays';
                    l_desc_final_tab := l_desc_final_tab MULTISET INTERSECT DISTINCT l_desc_tab;
                    l_val_final_tab  := l_val_final_tab MULTISET INTERSECT DISTINCT l_val_tab;
                END IF;
            ELSIF i_flg_type = 'U'
            THEN
                l_desc_final_tab := l_desc_final_tab MULTISET UNION l_desc_tab;
                l_val_final_tab  := l_val_final_tab MULTISET UNION l_val_tab;
            END IF;
        END LOOP;
    
        g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT t_desc.column_value label, t_val.column_value data
                          FROM (SELECT rownum rn, column_value
                                  FROM TABLE(l_desc_final_tab)) t_desc -- desc
                          JOIN (SELECT rownum rn, column_value
                                 FROM TABLE(l_val_final_tab)) t_val -- val
                            ON (t_desc.rn = t_val.rn)
                         ORDER BY label));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LATERALITY_ALL',
                                              l_error);
            RETURN t_tbl_core_domain();
    END get_laterality_all;

    FUNCTION get_laterality_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_laterality_mcdt IN table_varchar,
        i_flg_type            IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
    
        l_list pk_types.cursor_type;
        l_ret  t_tbl_core_domain;
    
        l_desc_tab       table_varchar;
        l_val_tab        table_varchar;
        l_img_tab        table_varchar;
        l_rank_tab       table_varchar;
        l_laterality_tab table_varchar := table_varchar();
    
        l_desc_final_tab       table_varchar := table_varchar();
        l_val_final_tab        table_varchar := table_varchar();
        l_laterality_final_tab table_varchar := table_varchar();
    
        l_flg_laterality_mcdt table_varchar;
    
        l_error t_error_out;
    BEGIN
        g_error := 'Init get_laterality';
        pk_alertlog.log_init(g_error);
    
        SELECT /*+opt_estimate (table t rows=1)*/
        DISTINCT t.column_value
          BULK COLLECT
          INTO l_flg_laterality_mcdt
          FROM TABLE(i_flg_laterality_mcdt) t;
    
        g_error := 'FOR i IN 1 .. ' || l_flg_laterality_mcdt.count;
        FOR i IN 1 .. l_flg_laterality_mcdt.count
        LOOP
            IF NOT pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_code_dom      => 'FLG_LATERALITY_' || l_flg_laterality_mcdt(i),
                                                  i_dep_clin_serv => NULL,
                                                  o_data_mkt      => l_list,
                                                  o_error         => l_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'FETCH l_list BULK COLLECT';
            FETCH l_list BULK COLLECT
                INTO l_desc_tab, l_val_tab, l_img_tab, l_rank_tab;
            CLOSE l_list;
        
            IF i_flg_type = 'I'
            THEN
            
                IF i = 1
                THEN
                    g_error          := 'arrays';
                    l_desc_final_tab := l_desc_tab;
                    l_val_final_tab  := l_val_tab;
                ELSE
                    g_error          := 'arrays';
                    l_desc_final_tab := l_desc_final_tab MULTISET INTERSECT DISTINCT l_desc_tab;
                    l_val_final_tab  := l_val_final_tab MULTISET INTERSECT DISTINCT l_val_tab;
                END IF;
            ELSIF i_flg_type = 'U'
            THEN
                IF i = 1
                THEN
                    l_desc_final_tab := l_desc_final_tab MULTISET UNION DISTINCT l_desc_tab;
                    l_val_final_tab  := l_val_final_tab MULTISET UNION DISTINCT l_val_tab;
                ELSE
                    l_desc_final_tab := l_desc_final_tab MULTISET INTERSECT DISTINCT l_desc_tab;
                    l_val_final_tab  := l_val_final_tab MULTISET INTERSECT DISTINCT l_val_tab;
                END IF;
            END IF;
            l_laterality_tab := table_varchar();
            l_laterality_tab.extend(l_val_tab.count);
        
            FOR j IN 1 .. l_val_tab.count
            LOOP
                l_laterality_tab(j) := l_flg_laterality_mcdt(i);
            END LOOP;
        
            l_laterality_final_tab := l_laterality_final_tab MULTISET UNION l_laterality_tab;
        
        END LOOP;
    
        g_error := 'OPEN l_list FOR';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => t_desc.column_value,
                                         domain_value  => t_val.column_value,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT rownum rn, column_value
                          FROM TABLE(l_desc_final_tab)) t_desc -- desc
                  JOIN (SELECT rownum rn, column_value
                         FROM TABLE(l_val_final_tab)) t_val -- val
                    ON (t_desc.rn = t_val.rn)
                  JOIN (SELECT rownum rn, column_value
                         FROM TABLE(l_laterality_final_tab)) t_lat -- laterality_mcdt
                    ON (t_desc.rn = t_lat.rn)
                 ORDER BY t_lat.column_value, t_desc.column_value);
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LATERALITY_ALL',
                                              l_error);
            RETURN l_ret;
    END get_laterality_all;

    /**
    * Returns a message if the field "Laterality" is not set for those MCDTs that has laterality mandatory
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_mcdt_type      Referral of MCDTs type
    * @param   i_mcdt           MCDTs identifiers
    * @param   o_flg_show       Flag indicating if the message is to be shown
    * @param   o_msg_title      Message title
    * @param   o_msg            Message text
    * @param   o_button         Type of button to show with message
    * @param   o_error          An error message, set when return=false
    *
    * @value   i_mcdt_type      {*} (A)nalysis {*} (I)mage {*} (E)xam {*} (P)rocedure {*} (M)fr
    * @value   o_flg_show       {*} 'Y' Message is to be shown {*} 'N' otherwise
    *    
    * @return    TRUE if sucess, FALSE otherwise
    *
    * @author    Ana Monteiro
    * @version   2.5
    * @since     30-08-2011
    */
    FUNCTION check_mandatory_lat
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_mcdt_type IN p1_external_request.flg_type%TYPE,
        i_mcdt      IN table_number,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_mandatory_laterality sys_config.value%TYPE;
        l_mcdt_desc            table_varchar;
    
        l_new_line VARCHAR2(20) := '<br><br>';
    
        -- gets exam names of exams that are mandatory
        CURSOR c_exam IS
            SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || e.id_exam, NULL)
              FROM exam_body_structure e
              JOIN TABLE(CAST(i_mcdt AS table_number)) t
                ON (t.column_value = e.id_exam)
             WHERE instr(l_mandatory_laterality, e.flg_main_laterality) != 0;
    
        -- gets intervention names of interventions that are mandatory
        CURSOR c_interv IS
            SELECT pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || i.id_intervention,
                                                              NULL)
              FROM interv_body_structure i
              JOIN TABLE(CAST(i_mcdt AS table_number)) t
                ON (t.column_value = i.id_intervention)
             WHERE instr(l_mandatory_laterality, i.flg_main_laterality) != 0;
    
    BEGIN
    
        g_error    := 'Init check_mandatory_lat';
        o_flg_show := pk_alert_constant.g_no;
    
        l_mandatory_laterality := pk_sysconfig.get_config(i_code_cf => 'MANDATORY_LATERALITY', i_prof => i_prof);
    
        IF i_mcdt_type = pk_ref_constant.g_p1_type_e
           OR i_mcdt_type = pk_ref_constant.g_p1_type_i
        THEN
            -- Exams and Imaging
            g_error := 'OPEN c_exam';
            OPEN c_exam;
            FETCH c_exam BULK COLLECT
                INTO l_mcdt_desc;
            CLOSE c_exam;
        
        ELSIF i_mcdt_type = pk_ref_constant.g_p1_type_p
              OR i_mcdt_type = pk_ref_constant.g_p1_type_f
        THEN
            -- Interventions and Rehab
            g_error := 'OPEN c_interv';
            OPEN c_interv;
            FETCH c_interv BULK COLLECT
                INTO l_mcdt_desc;
            CLOSE c_interv;
        END IF;
    
        IF l_mcdt_desc IS NOT NULL
           AND l_mcdt_desc.count > 0
        THEN
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang, pk_ref_constant.g_sm_doctor_cs_t078);
            o_msg       := pk_message.get_message(i_lang, 'ELECTR_PRESC_M001'); -- mandatory message
            o_button    := 'R';
        
            o_msg := REPLACE(o_msg, '@1', pk_message.get_message(i_lang, 'ELECTR_PRESC_T001')); -- Laterality field
        
            FOR i IN 1 .. l_mcdt_desc.count
            LOOP
                o_msg := o_msg || l_new_line || '- ' || l_mcdt_desc(i);
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    END check_mandatory_lat;

    /**********************************************************************************************
    * Diagnosis / MCDTS
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_mcdt                   mcdt id 
    * @param i_flg_type               I - Interventions, A - Analysis, E - Exams, O - Other Exams                     
    * @param o_diagnosis              array with diagnosis
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Teresa Coutinho
    * @version                        1.0 
    * @since                          2012/02/15
    **********************************************************************************************/
    FUNCTION get_mcdt_diag_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        i_mcdt      IN table_number,
        i_flg_type  IN mcdt_diagnosis.flg_type%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT p.gender, nvl(p.age, months_between(SYSDATE, p.dt_birth) / 12) age
              FROM patient p
              JOIN episode e
                ON e.id_patient = p.id_patient
             WHERE e.id_episode = i_epis;
    
        l_synonym_list_enable sys_config.value%TYPE;
        r_pat                 c_pat%ROWTYPE;
    
        g_diag_pesq      diagnosis.flg_type%TYPE := 'P';
        g_diag_available diagnosis.flg_available%TYPE := 'Y';
    BEGIN
        g_error := 'OPEN c_pat';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        -- enable/disable synonyms in search and reply result sets
        l_synonym_list_enable := nvl(pk_sysconfig.get_config('DIAGNOSIS_SYNONYMS_LIST_ENABLE', i_prof),
                                     pk_alert_constant.g_no);
    
        g_error := 'OPEN O_DIAGNOSIS (1)';
        OPEN o_diagnosis FOR
        
            SELECT *
              FROM (SELECT DISTINCT dc.id_diagnosis,
                                     pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                i_prof               => i_prof,
                                                                i_id_alert_diagnosis => dc.id_alert_diagnosis,
                                                                i_id_diagnosis       => dc.id_diagnosis,
                                                                i_code               => dc.code_icd,
                                                                i_flg_other          => dc.flg_other,
                                                                i_flg_std_diag       => dc.flg_icd9,
                                                                i_flg_search_mode    => pk_alert_constant.g_yes) desc_diagnosis,
                                     dc.code_icd,
                                     NULL status_diagnosis,
                                     NULL icon_status,
                                     pk_alert_constant.g_yes avail_for_select,
                                     NULL default_new_status,
                                     NULL default_new_status_desc,
                                     /*decode(dc.flg_icd9, pk_alert_constant.g_no,*/
                                     dc.id_alert_diagnosis /*, NULL)*/ AS id_alert_diagnosis
                       FROM mcdt_diagnosis md
                       JOIN diagnosis_content dc
                         ON md.id_alert_diagnosis = dc.id_alert_diagnosis
                       JOIN diagnosis_dep_clin_serv ddcs
                         ON (ddcs.id_diagnosis = dc.id_diagnosis AND
                            dc.id_alert_diagnosis = nvl(ddcs.id_alert_diagnosis, dc.id_alert_diagnosis))
                      WHERE md.id_mcdt IN (SELECT *
                                             FROM TABLE(i_mcdt))
                        AND md.flg_available = pk_alert_constant.g_yes
                        AND ddcs.flg_type = g_diag_pesq
                        AND ddcs.id_institution = i_prof.institution
                        AND ddcs.id_software = i_prof.software
                        AND md.flg_type = i_flg_type
                        AND dc.flg_type IN
                            (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                              column_value flg_terminology
                               FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc)
                        AND dc.flg_available = g_diag_available
                           -- show only available alert diagnoses
                        AND dc.flg_available = 'Y'
                           -- depending on synonym list enable cfg's, show diagnosis synonyms or not
                       AND (dc.flg_icd9 = 'Y' OR l_synonym_list_enable = 'Y')
                          -- show only selectable diagnoses
                       AND dc.flg_select = 'Y'
                          -- show only "medical past history" type of diagnoses 
                       AND dc.flg_type_dep_clin = 'M' --
                       AND ((r_pat.gender IS NOT NULL AND
                           coalesce(dc.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', r_pat.gender)) OR r_pat.gender IS NULL OR
                           r_pat.gender IN ('I', 'U', 'N'))
                       AND (nvl(r_pat.age, 0) BETWEEN nvl(dc.age_min, 0) AND nvl(dc.age_max, nvl(r_pat.age, 0)) OR
                           nvl(r_pat.age, 0) = 0)
                          --
                       AND rownum > 0) -- dummy condition in order to prevent performance issues
             WHERE desc_diagnosis IS NOT NULL
             ORDER BY desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MCDT_DIAG_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_mcdt_diag_list;

    FUNCTION get_questionnaire_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE
    ) RETURN table_varchar IS
    
        CURSOR c_patient IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_response table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
        SELECT qr.id_response || '|' || qr.desc_response || '|' || qr.flg_free_text
          BULK COLLECT
          INTO l_response
          FROM (SELECT qr.id_response,
                       pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) desc_response,
                       r.flg_free_text,
                       qr.rank
                  FROM questionnaire_response qr, response r
                 WHERE qr.id_questionnaire = i_questionnaire
                   AND qr.flg_available = pk_exam_constant.g_available
                   AND qr.id_response = r.id_response
                   AND r.flg_available = pk_exam_constant.g_available
                   AND (((l_patient.gender IS NOT NULL AND
                       coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                       l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                       (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND nvl(r.age_max, nvl(l_patient.age, 0)) OR
                       nvl(l_patient.age, 0) = 0))) qr
         ORDER BY qr.rank, qr.desc_response;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_questionnaire_response;

    FUNCTION get_questionnaire_alias
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_questionnaire IN questionnaire.code_questionnaire%TYPE
    ) RETURN VARCHAR2 IS
    
        c_questionnaire_alias pk_types.cursor_type;
    
        l_questionnaire_alias questionnaire_alias.code_questionnaire_alias%TYPE;
        o_desc_mess           pk_translation.t_desc_translation;
        o_error               t_error_out;
    
    BEGIN
    
        g_error := 'OPEN C_QUESTIONNAIRE_ALIAS';
        OPEN c_questionnaire_alias FOR
            SELECT (SELECT code_questionnaire_alias
                      FROM (SELECT code_questionnaire_alias,
                                   row_number() over(PARTITION BY qa.id_questionnaire ORDER BY qa.id_institution DESC, qa.id_software DESC) rn
                              FROM questionnaire_alias qa
                              JOIN questionnaire q
                                ON qa.id_questionnaire = q.id_questionnaire
                             WHERE decode(id_institution, 0, nvl(i_prof.institution, 0), id_institution) =
                                   nvl(i_prof.institution, 0)
                               AND decode(id_software, 0, nvl(i_prof.software, 0), id_software) = nvl(i_prof.software, 0)
                               AND q.code_questionnaire = i_code_questionnaire)
                     WHERE rn = 1)
              FROM dual;
    
        FETCH c_questionnaire_alias
            INTO l_questionnaire_alias;
        CLOSE c_questionnaire_alias;
    
        g_error := 'GET TRANSLATION';
        IF l_questionnaire_alias IS NOT NULL
        THEN
            o_desc_mess := pk_translation.get_translation(i_lang, l_questionnaire_alias);
        END IF;
    
        g_error := 'TEST OUTPUT MESSAGE';
        IF o_desc_mess IS NULL
        THEN
            o_desc_mess := pk_translation.get_translation(i_lang, i_code_questionnaire);
        END IF;
    
        RETURN o_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_QUESTIONNAIRE_ALIAS',
                                              o_error);
            RETURN NULL;
    END get_questionnaire_alias;

    FUNCTION get_response_alias
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_response IN response.code_response%TYPE
    ) RETURN VARCHAR2 IS
    
        c_response_alias pk_types.cursor_type;
    
        l_response_alias response_alias.code_response_alias%TYPE;
        o_desc_mess      pk_translation.t_desc_translation;
        o_error          t_error_out;
    
    BEGIN
    
        g_error := 'OPEN C_RESPONSE_ALIAS';
        OPEN c_response_alias FOR
            SELECT (SELECT code_response_alias
                      FROM (SELECT code_response_alias,
                                   row_number() over(PARTITION BY ra.id_response ORDER BY ra.id_institution DESC, ra.id_software DESC) rn
                              FROM response_alias ra
                              JOIN response r
                                ON ra.id_response = r.id_response
                             WHERE decode(id_institution, 0, nvl(i_prof.institution, 0), id_institution) =
                                   nvl(i_prof.institution, 0)
                               AND decode(id_software, 0, nvl(i_prof.software, 0), id_software) = nvl(i_prof.software, 0)
                               AND r.code_response = i_code_response)
                     WHERE rn = 1)
              FROM dual;
    
        FETCH c_response_alias
            INTO l_response_alias;
        CLOSE c_response_alias;
    
        g_error := 'GET TRANSLATION';
        IF l_response_alias IS NOT NULL
        THEN
            o_desc_mess := pk_translation.get_translation(i_lang, l_response_alias);
        END IF;
    
        g_error := 'TEST OUTPUT MESSAGE';
        IF o_desc_mess IS NULL
        THEN
            o_desc_mess := pk_translation.get_translation(i_lang, i_code_response);
        END IF;
    
        RETURN o_desc_mess;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RESPONSE_ALIAS',
                                              o_error);
            RETURN NULL;
    END get_response_alias;

    FUNCTION get_questionnaire_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_mcdt          IN NUMBER,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_flg_time      IN VARCHAR2,
        i_flg_type      IN VARCHAR2
    ) RETURN table_varchar IS
    
        CURSOR c_patient IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_response table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        IF i_flg_type = 'A' --Analysis
        THEN
            l_response := pk_lab_tests_utils.get_lab_test_response(i_lang,
                                                                   i_prof,
                                                                   i_patient,
                                                                   i_questionnaire,
                                                                   i_mcdt,
                                                                   i_sample_type,
                                                                   i_flg_time);
        ELSIF i_flg_type = 'E' -- Image Exams and Other Exams
        THEN
            l_response := pk_exam_utils.get_exam_response(i_lang,
                                                          i_prof,
                                                          i_patient,
                                                          i_questionnaire,
                                                          i_mcdt,
                                                          i_flg_time);
        ELSIF i_flg_type = 'P' -- Procedures
        THEN
            l_response := pk_procedures_utils.get_procedure_response(i_lang,
                                                                     i_prof,
                                                                     i_patient,
                                                                     i_questionnaire,
                                                                     i_mcdt,
                                                                     i_flg_time,
                                                                     NULL);
        
        ELSIF i_flg_type = 'BP'
        THEN
            l_response := pk_blood_products_utils.get_bp_response(i_lang,
                                                                  i_prof,
                                                                  i_patient,
                                                                  i_questionnaire,
                                                                  i_mcdt,
                                                                  i_flg_time);
        
        ELSE
            g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
            SELECT qr.id_response || '|' ||
                   pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) || '|' ||
                   r.flg_free_text
              BULK COLLECT
              INTO l_response
              FROM questionnaire_response qr, response r
             WHERE qr.id_questionnaire = i_questionnaire
               AND qr.flg_available = pk_alert_constant.g_available
               AND qr.id_response = r.id_response
               AND r.flg_available = pk_alert_constant.g_available
               AND (((l_patient.gender IS NOT NULL AND
                   coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                   l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                   (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND nvl(r.age_max, nvl(l_patient.age, 0)) OR
                   nvl(l_patient.age, 0) = 0))
             ORDER BY qr.rank;
        END IF;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_questionnaire_response;

    FUNCTION get_questionnaire_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_mcdt          IN NUMBER,
        i_sample_type   IN sample_type.id_sample_type%TYPE,
        i_flg_time      IN VARCHAR2,
        i_flg_type      IN VARCHAR2,
        i_inst_dest     IN institution.id_institution%TYPE
    ) RETURN table_varchar IS
    
        CURSOR c_patient IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_response table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        IF i_flg_type = 'A' --Analysis
        THEN
            l_response := pk_lab_tests_utils.get_lab_test_response(i_lang,
                                                                   i_prof,
                                                                   i_patient,
                                                                   i_questionnaire,
                                                                   i_mcdt,
                                                                   i_sample_type,
                                                                   i_flg_time);
        ELSIF i_flg_type = 'E' -- Image Exams and Other Exams
        THEN
            l_response := pk_exam_utils.get_exam_response(i_lang,
                                                          i_prof,
                                                          i_patient,
                                                          i_questionnaire,
                                                          i_mcdt,
                                                          i_flg_time);
        ELSIF i_flg_type = 'P' -- Procedures
        THEN
            l_response := pk_procedures_utils.get_procedure_response(i_lang,
                                                                     i_prof,
                                                                     i_patient,
                                                                     i_questionnaire,
                                                                     i_mcdt,
                                                                     i_flg_time,
                                                                     i_inst_dest);
        ELSIF i_flg_type = 'BP'
        THEN
            l_response := pk_blood_products_utils.get_bp_response(i_lang,
                                                                  i_prof,
                                                                  i_patient,
                                                                  i_questionnaire,
                                                                  i_mcdt,
                                                                  i_flg_time);
        ELSIF i_flg_type = 'COMM_ORDER'
        THEN
            l_response := pk_comm_orders.get_comm_order_response(i_lang,
                                                                 i_prof,
                                                                 i_patient,
                                                                 i_questionnaire,
                                                                 i_mcdt,
                                                                 i_flg_time);
        ELSE
            g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
            SELECT qr.id_response || '|' ||
                   pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) || '|' ||
                   r.flg_free_text
              BULK COLLECT
              INTO l_response
              FROM questionnaire_response qr, response r
             WHERE qr.id_questionnaire = i_questionnaire
               AND qr.flg_available = pk_alert_constant.g_available
               AND qr.id_response = r.id_response
               AND r.flg_available = pk_alert_constant.g_available
               AND (((l_patient.gender IS NOT NULL AND
                   coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                   l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                   (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND nvl(r.age_max, nvl(l_patient.age, 0)) OR
                   nvl(l_patient.age, 0) = 0))
             ORDER BY qr.rank;
        END IF;
    
        RETURN l_response;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_questionnaire_response;

    /**************************************************************************
    * Initializes parameters for filter MCDT_Diagnoses
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Sergio Dias
    * @since                         Oct-8-2014
    **************************************************************************/
    PROCEDURE init_params_mcdt_diagnosis
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_context_keys  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        l_func_name VARCHAR2(30 CHAR) := 'INIT_PARAMS_MCDT_DIAGNOSIS';
        -- context vars indexes, text_search (1) and diag_flg_type (2) are loaded in pk_terminology_search.init_params_diagnosis
        l_mcdt_flg_type_idx CONSTANT NUMBER(24) := 3;
        l_mcdt_ids_idx      CONSTANT NUMBER(24) := 4;
    BEGIN
        g_error := 'CALL PK_TERMINOLOGY_SEARCH.INIT_PARAMS_DIAGNOSIS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        pk_terminology_search.init_params_diagnosis(i_filter_name   => i_filter_name,
                                                    i_custom_filter => i_custom_filter,
                                                    i_context_ids   => i_context_ids,
                                                    i_context_vals  => i_context_vals,
                                                    i_name          => i_name,
                                                    o_vc2           => o_vc2,
                                                    o_num           => o_num,
                                                    o_id            => o_id,
                                                    o_tstz          => o_tstz);
    
        g_error := 'LOAD L_MCDT_FLG_TYPE_IDX AND L_MCDT_IDS_IDX';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF i_context_vals.exists(l_mcdt_flg_type_idx)
        THEN
            pk_context_api.set_parameter(g_mcdt_flg_type, i_context_vals(l_mcdt_flg_type_idx));
        END IF;
    
        IF i_context_vals.exists(l_mcdt_ids_idx)
        THEN
            pk_context_api.set_parameter(g_mcdt_ids, i_context_vals(l_mcdt_ids_idx));
        END IF;
    
    END init_params_mcdt_diagnosis;

    /**************************************************************************************************************
    * Table function to return filter content
    *
    * @return                           Returns the diagnosis configured for a set of MCDT
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.1
    * @since                            Oct-8-2014
    **************************************************************************************************************/
    FUNCTION tf_mcdt_diag_list RETURN t_coll_diagnosis_config IS
        l_func_name              VARCHAR2(30 CHAR) := 'TF_MCDT_DIAG_LIST';
        l_lang                   language.id_language%TYPE;
        l_patient                patient.id_patient%TYPE;
        l_prof                   profissional;
        l_episode                episode.id_episode%TYPE;
        l_text_search            translation.desc_lang_1%TYPE;
        l_profile_template       profile_template.id_profile_template%TYPE;
        l_epis_diag_type         epis_diagnosis.flg_type%TYPE;
        l_tbl_diagnosis          t_coll_diagnosis_config;
        l_tbl_id_alert_diagnosis table_number;
        l_synonym_list_enable    sys_config.value%TYPE;
        g_diag_pesq              diagnosis.flg_type%TYPE := 'P';
        l_mcdt_ids_string        VARCHAR2(4000 CHAR);
        l_mcdt_flg_type          VARCHAR2(1 CHAR);
    
        CURSOR c_pat IS
            SELECT p.gender, nvl(p.age, months_between(SYSDATE, p.dt_birth) / 12) age
              FROM patient p
              JOIN episode e
                ON e.id_patient = p.id_patient
             WHERE e.id_episode = l_episode;
        r_pat c_pat%ROWTYPE;
    
        PROCEDURE load_mcdt_values IS
            l_proc_name CONSTANT VARCHAR2(30) := 'LOAD_SEARCH_VALUES';
        BEGIN
            g_error := 'GET MCDT INFO';
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => l_proc_name);
            l_mcdt_flg_type   := sys_context(pk_terminology_search.g_alert_context, g_mcdt_flg_type);
            l_mcdt_ids_string := sys_context(pk_terminology_search.g_alert_context, g_mcdt_ids);
        END;
    
    BEGIN
        g_error := 'LOAD_SEARCH_VALUES - TF_MCDT_DIAG_LIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        pk_terminology_search.load_search_values(o_lang             => l_lang,
                                                 o_prof             => l_prof,
                                                 o_profile_template => l_profile_template,
                                                 o_id_patient       => l_patient,
                                                 o_episode          => l_episode,
                                                 o_text_search      => l_text_search,
                                                 o_epis_diag_type   => l_epis_diag_type);
    
        load_mcdt_values;
    
        IF l_mcdt_flg_type IS NULL
           OR l_mcdt_ids_string IS NULL
        THEN
            RETURN t_coll_diagnosis_config();
        END IF;
    
        g_error := 'OPEN C_PAT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        -- enable/disable synonyms in search and reply result sets
        l_synonym_list_enable := nvl(pk_sysconfig.get_config('DIAGNOSIS_SYNONYMS_LIST_ENABLE', l_prof),
                                     pk_alert_constant.g_no);
    
        g_error := 'LOAD L_TBL_ID_ALERT_DIAGNOSIS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT DISTINCT dc.id_alert_diagnosis
          BULK COLLECT
          INTO l_tbl_id_alert_diagnosis
          FROM mcdt_diagnosis md
          JOIN diagnosis_content dc
            ON md.id_alert_diagnosis = dc.id_alert_diagnosis
          JOIN diagnosis_dep_clin_serv ddcs
            ON (ddcs.id_diagnosis = dc.id_diagnosis AND
               dc.id_alert_diagnosis = nvl(ddcs.id_alert_diagnosis, dc.id_alert_diagnosis))
         WHERE md.id_mcdt IN (SELECT *
                                FROM TABLE(pk_utils.str_split_n(l_mcdt_ids_string, '|')))
           AND md.flg_available = pk_alert_constant.g_yes
           AND ddcs.flg_type = g_diag_pesq
           AND ddcs.id_institution = l_prof.institution
           AND ddcs.id_software = l_prof.software
           AND md.flg_type = l_mcdt_flg_type
           AND dc.flg_type IN
               (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                 column_value flg_terminology
                  FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => l_lang,
                                                                      i_prof      => l_prof,
                                                                      i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc)
           AND dc.flg_available = pk_alert_constant.g_yes
           AND (dc.flg_icd9 = pk_alert_constant.g_yes OR l_synonym_list_enable = pk_alert_constant.g_yes)
           AND dc.flg_select = pk_alert_constant.g_yes
           AND dc.flg_type_dep_clin = 'M'
           AND ((r_pat.gender IS NOT NULL AND coalesce(dc.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', r_pat.gender)) OR
               r_pat.gender IS NULL OR r_pat.gender IN ('I', 'U', 'N'))
           AND (nvl(r_pat.age, 0) BETWEEN nvl(dc.age_min, 0) AND nvl(dc.age_max, nvl(r_pat.age, 0)) OR
               nvl(r_pat.age, 0) = 0)
           AND rownum > 0;
    
        IF l_tbl_id_alert_diagnosis.exists(1)
        THEN
            g_error := 'CALL PK_TERMINOLOGY_SEARCH.TF_DIAGNOSES_SEARCH';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
            SELECT t_rec_diagnosis_config(id_diagnosis            => a.id_diagnosis,
                                          id_diagnosis_parent     => a.id_diagnosis_parent,
                                          id_epis_diagnosis       => NULL,
                                          desc_diagnosis          => a.desc_translation,
                                          code_icd                => a.code_icd,
                                          flg_other               => a.flg_other,
                                          status_diagnosis        => NULL,
                                          icon_status             => NULL,
                                          avail_for_select        => a.flg_select,
                                          default_new_status      => NULL,
                                          default_new_status_desc => NULL,
                                          id_alert_diagnosis      => a.id_alert_diagnosis,
                                          desc_epis_diagnosis     => NULL,
                                          flg_terminology         => a.flg_terminology,
                                          flg_diag_type           => NULL,
                                          rank                    => a.rank,
                                          code_diagnosis          => a.code_translation,
                                          flg_icd9                => a.flg_icd9,
                                          flg_show_term_code      => a.flg_show_term_code,
                                          id_language             => a.id_language)
              BULK COLLECT
              INTO l_tbl_diagnosis
              FROM (SELECT b.*
                      FROM (TABLE(pk_terminology_search.tf_diagnoses_search(i_lang                => l_lang,
                                                                            i_prof                => l_prof,
                                                                            i_patient             => l_patient,
                                                                            i_text_search         => l_text_search,
                                                                            i_tbl_alert_diagnosis => l_tbl_id_alert_diagnosis,
                                                                            i_list_type           => pk_terminology_search.g_diag_list_searchable)) b)) a;
        ELSE
            l_tbl_diagnosis := t_coll_diagnosis_config();
        END IF;
        RETURN l_tbl_diagnosis;
    END tf_mcdt_diag_list;

    /** @headcom
    * Public Function. Cancelar associa��es de diagn�sticos a MCDTs e de Medica��o a Problemas
    *
    * @param    i_lang              L�ngua registada como prefer�ncia do profissional
    * @param    i_flg_type          Distingue o tipo de associa��o: 'M' para MCDTs, 'P' para prescri��o
    * @param    i_ids               Array com um conjunto de associa��es a eliminar. 
    *                                Qd i_flg_type='M' ent�o os Ids referen-se a MCDT_REQ_DET. 
    *                               Qd i_flg_type='P' ent�o os Ids referen-se a PRESC_PAT_PROBLEM.
    * @param      I_PROF            Object (ID do profissional, ID da institui��o, ID do software)
    * @param      I_PROF_CAT_TYPE   Categoria do profissional (flag)
    * @param      i_test            'Y' indica que � para pedir mensagem de confirma��o. 'N' indica que para realizar ro pedido.
    * @param      O_FLG_SHOW         flag: Y - existe msg para mostrar; N - � existe  
    * @param      O_MSG              mensagem a mostrar
    * @param      O_MSG_TITLE        t�tulo da mensagem
    * @param      O_BUTTON           bot�es a mostrar: N - n�o, R - lido, C - confirmado 
    * @param      O_ERROR            erro
    *
    * @return     boolean
    * @author     Lu�s Gaspar
    * @version    0.1
    * @since      2007/08/10
    */

    FUNCTION cancel_associated_problem
    (
        i_lang          IN language.id_language%TYPE,
        i_flg_type      IN table_varchar,
        i_ids           IN table_number,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        fatal EXCEPTION;
        l_association_type   VARCHAR(2); -- M: medica��o, P: precri��o, MP/PM:Medica��o+Prescri��o
        l_mcdt_req_diag      mcdt_req_diagnosis%ROWTYPE;
        l_presc_pat_paroblem presc_pat_problem%ROWTYPE;
        l_association_desc1  pk_translation.t_desc_translation;
        l_association_desc2  pk_translation.t_desc_translation;
        l_association_desc   pk_translation.t_desc_translation;
    
        k_flg_cancel VARCHAR2(1) := 'C';
    
    BEGIN
        -- check execution mode: message confirmation or execution 
        IF (i_test = 'Y')
        THEN
            -- compose message
            o_msg       := pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M045');
            o_msg_title := pk_message.get_message(i_lang, 'PRESCRIPTION_PHARM_M031');
            FOR i IN i_ids.first .. i_ids.last
            LOOP
                IF (i_flg_type(i) = 'M')
                THEN
                    -- association between MCDT and diagnosis, get descriptions
                    SELECT pk_translation.get_translation(i_lang, d.code_diagnosis),
                           decode(e.code_exam,
                                  NULL,
                                  decode(a.code_analysis,
                                         NULL,
                                         pk_procedures_api_db.get_alias_translation(i_lang,
                                                                                    i_prof,
                                                                                    it.code_intervention,
                                                                                    NULL),
                                         pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                                   i_prof,
                                                                                   'A',
                                                                                   a.code_analysis,
                                                                                   NULL)),
                                  pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam, NULL))
                      INTO l_association_desc1, l_association_desc2
                      FROM mcdt_req_diagnosis mrd
                      JOIN diagnosis d
                        ON d.id_diagnosis = mrd.id_diagnosis
                      LEFT JOIN exam_req_det erd
                        ON erd.id_exam_req_det = mrd.id_exam_req_det
                      LEFT JOIN exam e
                        ON erd.id_exam = e.id_exam
                      LEFT JOIN analysis_req_det ard
                        ON ard.id_analysis_req_det = mrd.id_analysis_req_det
                      LEFT JOIN analysis a
                        ON a.id_analysis = ard.id_analysis
                      LEFT JOIN interv_presc_det ipd
                        ON ipd.id_interv_presc_det = mrd.id_interv_presc_det
                      LEFT JOIN intervention it
                        ON it.id_intervention = ipd.id_intervention
                     WHERE mrd.id_mcdt_req_diagnosis = i_ids(i);
                ELSIF (i_flg_type(i) = 'MFR')
                THEN
                    -- association between Intervention MFR and diagnosis, get descriptions
                    SELECT nvl(pk_translation.get_translation(i_lang,
                                                              decode(adp.id_alert_diagnosis,
                                                                     NULL,
                                                                     decode(a.id_allergy,
                                                                            NULL,
                                                                            decode(d.id_diagnosis,
                                                                                   NULL,
                                                                                   decode(edd.id_diagnosis,
                                                                                          NULL,
                                                                                          decode(pp.desc_pat_problem,
                                                                                                 NULL,
                                                                                                 h.code_habit,
                                                                                                 pp.desc_pat_problem),
                                                                                          edd.code_diagnosis),
                                                                                   d.code_diagnosis),
                                                                            a.code_allergy),
                                                                     adp.code_alert_diagnosis)),
                               desc_pat_history_diagnosis),
                           pk_translation.get_translation(i_lang, i.code_intervention)
                      INTO l_association_desc1, l_association_desc2
                      FROM interv_pat_problem ipp
                      LEFT JOIN pat_problem pp
                        ON pp.id_pat_problem = ipp.id_pat_problem
                      LEFT JOIN diagnosis d
                        ON d.id_diagnosis = pp.id_diagnosis
                      LEFT JOIN epis_diagnosis ed
                        ON ed.id_epis_diagnosis = pp.id_epis_diagnosis
                      LEFT JOIN diagnosis edd
                        ON edd.id_diagnosis = ed.id_diagnosis
                      LEFT JOIN pat_history_diagnosis phd
                        ON phd.id_pat_history_diagnosis = ipp.id_pat_history_diagnosis
                      LEFT JOIN alert_diagnosis adp
                        ON adp.id_alert_diagnosis = phd.id_alert_diagnosis
                      LEFT JOIN diagnosis adpd
                        ON adpd.id_diagnosis = adp.id_diagnosis
                      LEFT JOIN pat_allergy pa
                        ON ipp.id_pat_allergy = pa.id_pat_allergy
                      LEFT JOIN allergy a
                        ON a.id_allergy = pa.id_allergy
                      JOIN interv_presc_det ipd
                        ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
                      LEFT JOIN intervention i
                        ON ipd.id_intervention = i.id_intervention
                      LEFT JOIN pat_habit ph
                        ON pp.id_pat_habit = ph.id_pat_habit
                      LEFT JOIN habit h
                        ON ph.id_habit = h.id_habit
                     WHERE ipp.id_interv_pat_problem = i_ids(i);
                ELSE
                    NULL;
                END IF;
                -- build message token
                IF (l_association_desc IS NOT NULL)
                THEN
                    l_association_desc := l_association_desc || chr(10);
                END IF;
                l_association_desc := l_association_desc || l_association_desc1 || ' <=> ' || l_association_desc2;
            END LOOP;
            -- replace token
            o_msg := REPLACE(o_msg, '@1', l_association_desc);
            RETURN TRUE;
        END IF;
        -- perform cancel association
        FOR i IN i_ids.first .. i_ids.last
        LOOP
            IF (i_flg_type(i) = 'M')
            THEN
                -- cancel association at mcdt_req_diagnosis
                UPDATE mcdt_req_diagnosis mrd
                   SET mrd.flg_status     = k_flg_cancel,
                       mrd.id_prof_cancel = i_prof.id,
                       mrd.dt_cancel_tstz = current_timestamp
                 WHERE mrd.id_mcdt_req_diagnosis = i_ids(i);
                -- validate mcdt_req_diagnosis id
                IF SQL%NOTFOUND
                THEN
                    RAISE fatal;
                END IF;
            ELSIF (i_flg_type(i) = 'MFR')
            THEN
                -- cancel association at interv_pat_problem
                UPDATE interv_pat_problem ipp
                   SET ipp.flg_status     = k_flg_cancel,
                       ipp.id_prof_cancel = i_prof.id,
                       ipp.dt_cancel_tstz = current_timestamp
                 WHERE ipp.id_interv_pat_problem = i_ids(i);
                -- validate interv_pat_problem id
                IF SQL%NOTFOUND
                THEN
                    RAISE fatal;
                END IF;
            ELSE
                NULL;
            END IF;
        END LOOP
        
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN fatal THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CANCEL_ASSOCIATED_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alertlog.log_debug(o_error.ora_sqlerrm);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CANCEL_ASSOCIATED_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT pk_types.cursor_type,
        o_ds_target   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_area table_varchar;
    
        l_table_components t_clin_quest_table;
        l_table_target     t_clin_quest_target_table;
    
        l_exception EXCEPTION;
    BEGIN
    
        l_area := pk_string_utils.str_split(i_list => i_screen_name, i_delim => '_');
    
        CASE l_area(1)
        
            WHEN 'CLINQUESTORDERSETS' THEN
            
                IF NOT pk_order_sets.get_full_items_by_screen(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_patient     => i_patient,
                                                              i_episode     => i_episode,
                                                              i_screen_name => l_area(2),
                                                              i_action      => i_action,
                                                              o_components  => l_table_components,
                                                              o_ds_target   => l_table_target,
                                                              o_error       => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                OPEN o_components FOR
                    SELECT DISTINCT id_ds_cmpt_mkt_rel,
                                    id_ds_component_parent,
                                    code_alt_desc,
                                    desc_component,
                                    internal_name,
                                    flg_data_type,
                                    internal_sample_text_type,
                                    id_ds_component_child,
                                    rank,
                                    max_len,
                                    min_len,
                                    min_value,
                                    max_value,
                                    position,
                                    flg_multichoice,
                                    comp_size,
                                    flg_wrap_text,
                                    multichoice_code,
                                    service_params,
                                    flg_event_type,
                                    flg_exp_type,
                                    input_expression,
                                    input_mask,
                                    comp_offset,
                                    flg_hidden,
                                    placeholder,
                                    validation_message,
                                    flg_clearable,
                                    crate_identifier,
                                    rn,
                                    flg_repeatable,
                                    flg_data_type2,
                                    text_line_nr
                      FROM TABLE(l_table_components)
                     ORDER BY id_ds_component_parent NULLS FIRST;
            
                OPEN o_ds_target FOR
                    SELECT DISTINCT id_cmpt_mkt_origin,
                                    id_cmpt_origin,
                                    id_ds_event,
                                    flg_type,
                                    VALUE,
                                    id_cmpt_mkt_dest,
                                    id_cmpt_dest,
                                    field_mask,
                                    flg_event_target_type,
                                    validation_message,
                                    rn
                      FROM TABLE(l_table_target);
            
            WHEN 'CLINQUESTPROCEDURES' THEN
                IF NOT pk_procedures_utils.get_full_items_by_screen(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_patient     => i_patient,
                                                                    i_episode     => i_episode,
                                                                    i_screen_name => l_area(2),
                                                                    i_action      => i_action,
                                                                    o_components  => l_table_components,
                                                                    o_ds_target   => l_table_target,
                                                                    o_error       => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                OPEN o_components FOR
                    SELECT *
                      FROM TABLE(l_table_components);
            
                OPEN o_ds_target FOR
                    SELECT *
                      FROM TABLE(l_table_target);
            
            WHEN 'CLINQUESTEXAMS' THEN
                IF NOT pk_exam_utils.get_full_items_by_screen(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_patient     => i_patient,
                                                              i_episode     => i_episode,
                                                              i_screen_name => l_area(2),
                                                              i_action      => i_action,
                                                              o_components  => l_table_components,
                                                              o_ds_target   => l_table_target,
                                                              o_error       => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                OPEN o_components FOR
                    SELECT *
                      FROM TABLE(l_table_components);
            
                OPEN o_ds_target FOR
                    SELECT *
                      FROM TABLE(l_table_target);
            
            WHEN 'CLINQUESTLABTESTS' THEN
                IF NOT pk_lab_tests_utils.get_full_items_by_screen(i_lang        => i_lang,
                                                                   i_prof        => i_prof,
                                                                   i_patient     => i_patient,
                                                                   i_episode     => i_episode,
                                                                   i_screen_name => l_area(2),
                                                                   i_action      => i_action,
                                                                   o_components  => l_table_components,
                                                                   o_ds_target   => l_table_target,
                                                                   o_error       => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                OPEN o_components FOR
                    SELECT *
                      FROM TABLE(l_table_components);
            
                OPEN o_ds_target FOR
                    SELECT *
                      FROM TABLE(l_table_target);
            
            WHEN 'CLINQUESTBLOODPRODUCTS' THEN
                IF NOT pk_blood_products_utils.get_full_items_by_screen(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_patient     => i_patient,
                                                                        i_episode     => i_episode,
                                                                        i_screen_name => l_area(2),
                                                                        i_action      => i_action,
                                                                        o_components  => l_table_components,
                                                                        o_ds_target   => l_table_target,
                                                                        o_error       => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                OPEN o_components FOR
                    SELECT *
                      FROM TABLE(l_table_components);
            
                OPEN o_ds_target FOR
                    SELECT *
                      FROM TABLE(l_table_target);
            
            WHEN 'CLINQUESTREHAB' THEN
                IF NOT pk_rehab.get_full_items_by_screen(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_patient     => i_patient,
                                                         i_episode     => i_episode,
                                                         i_screen_name => l_area(2),
                                                         i_action      => i_action,
                                                         o_components  => l_table_components,
                                                         o_ds_target   => l_table_target,
                                                         o_error       => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                OPEN o_components FOR
                    SELECT *
                      FROM TABLE(l_table_components);
            
                OPEN o_ds_target FOR
                    SELECT *
                      FROM TABLE(l_table_target);
            
            ELSE
                NULL;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION',
                                              'CANCEL_ASSOCIATED_PROBLEM',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_cursor_if_closed(o_components);
            pk_types.open_cursor_if_closed(o_ds_target);
            RETURN FALSE;
    END get_full_items_by_screen;

    FUNCTION get_multichoice_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_field   IN VARCHAR2
    ) RETURN t_tbl_core_domain IS
        c_myfunction CONSTANT VARCHAR2(100) := 'PK_ORDERS_UTILS.get_multichoice_options';
        l_var   t_tbl_multichoice_option := NEW t_tbl_multichoice_option();
        l_ret   t_tbl_core_domain;
        l_row   t_row_core_domain;
        l_error t_error_out;
    
        l_tbl_aux_flg_type table_varchar;
        l_flg_type         VARCHAR2(5 CHAR);
    
        l_tbl_aux_data  table_varchar;
        l_questionnaire NUMBER(24);
        l_mcdt          NUMBER(24);
        l_sample_type   NUMBER(24);
        l_flg_time      VARCHAR2(1 CHAR);
    
        CURSOR c_patient IS
            SELECT gender, months_between(SYSDATE, dt_birth) / 12 age
              FROM patient
             WHERE id_patient = i_patient;
    
        l_patient c_patient%ROWTYPE;
    
        l_response table_varchar;
    
        l_tbl_response_aux table_varchar;
        l_id_response      NUMBER(24);
        l_desc_response    VARCHAR2(100 CHAR);
        l_free_text        VARCHAR2(5 CHAR);
    
    BEGIN
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_patient;
        CLOSE c_patient;
    
        l_tbl_aux_flg_type := pk_string_utils.str_split(i_field, '|');
        l_flg_type         := l_tbl_aux_flg_type(1);
    
        l_tbl_aux_data := pk_string_utils.str_split(l_tbl_aux_flg_type(2), '_');
    
        l_mcdt          := l_tbl_aux_data(1);
        l_questionnaire := l_tbl_aux_data(2);
        l_flg_time      := 'O';
    
        IF l_flg_type = 'A' --Analysis
        THEN
            l_sample_type := l_tbl_aux_data(3);
            l_response    := pk_lab_tests_utils.get_lab_test_response(i_lang,
                                                                      i_prof,
                                                                      i_patient,
                                                                      l_questionnaire,
                                                                      l_mcdt,
                                                                      l_sample_type,
                                                                      l_flg_time);
        ELSIF l_flg_type = 'E' -- Image Exams and Other Exams
        THEN
            l_response := pk_exam_utils.get_exam_response(i_lang,
                                                          i_prof,
                                                          i_patient,
                                                          l_questionnaire,
                                                          l_mcdt,
                                                          l_flg_time);
        ELSIF l_flg_type = 'P' -- Procedures
        THEN
            l_response := pk_procedures_utils.get_procedure_response(i_lang,
                                                                     i_prof,
                                                                     i_patient,
                                                                     l_questionnaire,
                                                                     l_mcdt,
                                                                     l_flg_time,
                                                                     NULL);
        
        ELSIF l_flg_type = 'BP'
        THEN
            l_response := pk_blood_products_utils.get_bp_response(i_lang,
                                                                  i_prof,
                                                                  i_patient,
                                                                  l_questionnaire,
                                                                  l_mcdt,
                                                                  l_flg_time);
        
        ELSE
            g_error := 'SELECT QUESTIONNAIRE_RESPONSE';
            SELECT qr.id_response || '|' ||
                   pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) || '|' ||
                   r.flg_free_text
              BULK COLLECT
              INTO l_response
              FROM questionnaire_response qr, response r
             WHERE qr.id_questionnaire = l_questionnaire
               AND qr.flg_available = pk_alert_constant.g_available
               AND qr.id_response = r.id_response
               AND r.flg_available = pk_alert_constant.g_available
               AND (((l_patient.gender IS NOT NULL AND
                   coalesce(r.gender, 'I', 'U', 'N') IN ('I', 'U', 'N', l_patient.gender)) OR
                   l_patient.gender IS NULL OR l_patient.gender IN ('I', 'U', 'N')) AND
                   (nvl(l_patient.age, 0) BETWEEN nvl(r.age_min, 0) AND nvl(r.age_max, nvl(l_patient.age, 0)) OR
                   nvl(l_patient.age, 0) = 0))
             ORDER BY qr.rank;
        END IF;
    
        l_ret := t_tbl_core_domain();
        FOR i IN 1 .. l_response.count
        LOOP
            l_tbl_response_aux := pk_string_utils.str_split(l_response(i), '|');
            l_id_response      := l_tbl_response_aux(1);
            l_desc_response    := l_tbl_response_aux(2);
            l_free_text        := l_tbl_response_aux(3);
        
            l_row := t_row_core_domain(internal_name => NULL,
                                       desc_domain   => l_desc_response,
                                       domain_value  => l_id_response,
                                       order_rank    => i,
                                       img_name      => NULL);
            l_ret.extend;
            l_ret(l_ret.count) := l_row;
        
        END LOOP;
    
        /*SELECT *
        BULK COLLECT
        INTO l_ret
        FROM (SELECT t_row_core_domain(internal_name => NULL,
                                       desc_domain   => t.label,
                                       domain_value  => t.data,
                                       order_rank    => t.rank,
                                       img_name      => NULL)
                FROM (TABLE(l_response) t));*/
    
        /* g_error := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => t.label,
                                         domain_value  => t.data,
                                         order_rank    => t.rank,
                                         img_name      => NULL)
                  FROM (SELECT qr.id_response data,
                               pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response) label,
                               r.flg_free_text,
                               qr.rank rank
                          FROM questionnaire_response qr, response r
                         WHERE qr.id_questionnaire = to_number(i_field)
                           AND qr.flg_available = pk_exam_constant.g_available
                           AND qr.id_response = r.id_response
                           AND r.flg_available = pk_exam_constant.g_available) t);*/
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_myfunction,
                                              l_error);
            RETURN l_ret;
    END get_multichoice_options;

    FUNCTION get_request_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_int_name   IN table_varchar,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_area table_varchar;
    BEGIN
        l_area := pk_string_utils.str_split(i_list => i_root_name, i_delim => '_');
    
        CASE l_area(1)
            WHEN 'CLINQUESTREHAB' THEN
                tbl_result := pk_rehab.get_request_values(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_episode        => i_episode,
                                                          i_patient        => i_patient,
                                                          i_action         => i_action,
                                                          i_root_name      => i_root_name,
                                                          i_curr_component => i_curr_component,
                                                          i_tbl_int_name   => i_tbl_int_name,
                                                          i_tbl_id_pk      => i_tbl_id_pk,
                                                          i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                          i_value          => i_value,
                                                          o_error          => o_error);
            WHEN 'CLINQUESTPROCEDURES' THEN
                tbl_result := pk_procedures_core.get_procedure_cq_values(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_episode        => i_episode,
                                                                         i_patient        => i_patient,
                                                                         i_action         => i_action,
                                                                         i_root_name      => i_root_name,
                                                                         i_curr_component => i_curr_component,
                                                                         i_tbl_int_name   => i_tbl_int_name,
                                                                         i_tbl_id_pk      => i_tbl_id_pk,
                                                                         i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                                         i_value          => i_value,
                                                                         o_error          => o_error);
        END CASE;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REQUEST_VALUES',
                                              o_error);
            RETURN NULL;
    END get_request_values;

    FUNCTION get_docs_by_request
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_episode  IN NUMBER,
        i_flg_area IN VARCHAR2,
        i_request  IN NUMBER, -- edit, new, submit
        o_docs     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        CASE
            WHEN i_flg_area = 'P' THEN
                IF NOT pk_procedures_core.get_docs_by_request(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode,
                                                              i_request => i_request,
                                                              o_docs    => o_docs,
                                                              o_error   => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            ELSE
                NULL;
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOCS_BY_REQUEST',
                                              o_error);
            RETURN FALSE;
    END get_docs_by_request;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_mcdt;
/
