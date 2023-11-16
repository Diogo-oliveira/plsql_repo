/*-- Last Change Revision: $Rev: 2027235 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_image_tech AS

    FUNCTION set_exam_grid_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_type     IN exam.flg_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exam_req IS
            SELECT erd.id_exam,
                   erd.flg_referral,
                   e.id_exam_cat,
                   er.id_prof_req,
                   er.id_episode,
                   erd.id_exec_institution,
                   er.dt_begin_tstz,
                   er.dt_req_tstz,
                   er.dt_pend_req_tstz,
                   er.dt_schedule_tstz,
                   er.flg_time,
                   erd.flg_status,
                   erd.id_room,
                   m.flg_status,
                   m.dt_req_tstz,
                   m.dt_end_tstz,
                   CASE
                        WHEN erd.flg_status = pk_exam_constant.g_exam_result THEN
                         CASE
                             WHEN erd.flg_priority != pk_exam_constant.g_exam_normal THEN
                              rs.value || pk_exam_constant.g_exam_urgent
                             ELSE
                              CASE
                                  WHEN eres.id_abnormality IS NOT NULL
                                       AND eres.id_abnormality != 7 THEN
                                   rs.value || pk_exam_constant.g_exam_urgent
                                  ELSE
                                   rs.value
                              END
                         END
                        ELSE
                         rs.value
                    END flg_status_r,
                   erd.id_task_dependency,
                   erd.flg_req_origin_module,
                   pk_announced_arrival.get_ann_arrival_id(i_prof.institution,
                                                           ei.id_software,
                                                           er.id_episode,
                                                           ei.flg_unknown,
                                                           aa.id_announced_arrival,
                                                           aa.flg_status) id_announced_arrival
              FROM exam e,
                   exam_req er,
                   exam_req_det erd,
                   (SELECT *
                      FROM exam_result er
                     WHERE er.flg_status != pk_exam_constant.g_exam_cancel) eres,
                   result_status rs,
                   movement m,
                   announced_arrival aa,
                   epis_info ei
             WHERE er.id_exam_req = erd.id_exam_req
               AND er.id_exam_req = i_exam_req
               AND er.id_exam_req NOT IN (SELECT id_exam_req
                                            FROM exam_req
                                           WHERE id_episode_origin IS NOT NULL
                                             AND dt_pend_req_tstz IS NULL
                                             AND flg_time = pk_exam_constant.g_flg_time_e)
               AND erd.id_exam_req_det = i_exam_req_det
               AND erd.id_exam_req_det = eres.id_exam_req_det(+)
               AND eres.id_result_status = rs.id_result_status(+)
               AND erd.id_movement = m.id_movement(+)
               AND erd.id_exam = e.id_exam
               AND e.flg_type = pk_exam_constant.g_type_img
               AND (er.id_episode = ei.id_episode OR er.id_episode_origin = ei.id_episode)
               AND er.id_episode = aa.id_episode(+)
            UNION ALL
            SELECT erd.id_exam,
                   erd.flg_referral,
                   e.id_exam_cat,
                   er.id_prof_req,
                   er.id_episode,
                   erd.id_exec_institution,
                   er.dt_begin_tstz,
                   er.dt_req_tstz,
                   er.dt_pend_req_tstz,
                   er.dt_schedule_tstz,
                   er.flg_time,
                   erd.flg_status,
                   erd.id_room,
                   NULL                      flg_status,
                   NULL                      dt_req_tstz,
                   NULL                      dt_end_tstz,
                   NULL                      flg_status_r,
                   erd.id_task_dependency,
                   erd.flg_req_origin_module,
                   NULL                      id_announced_arrival
              FROM exam e, exam_req er, exam_req_det erd
             WHERE er.id_exam_req = erd.id_exam_req
               AND er.id_exam_req = i_exam_req
               AND erd.id_exam_req_det = i_exam_req_det
               AND erd.id_exam = e.id_exam
               AND e.flg_type = pk_exam_constant.g_type_img
               AND er.id_episode IS NULL
               AND er.id_episode_origin IS NULL;
    
        CURSOR c_patient IS
            SELECT nvl(i_patient, p.id_patient) id_patient,
                   p.gender,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   cr.num_clin_record
              FROM exam_req er, patient p, clin_record cr
             WHERE er.id_exam_req = i_exam_req
               AND er.id_patient = p.id_patient
               AND p.id_patient = cr.id_patient(+)
               AND cr.id_institution(+) = i_prof.institution;
    
        CURSOR c_episode IS
            SELECT e.id_epis_type,
                   e.flg_status,
                   e.id_clinical_service,
                   pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution) id_software
              FROM episode e
             WHERE e.id_episode = i_episode
               AND e.flg_status != pk_alert_constant.g_epis_status_cancel;
    
        CURSOR c_epis_info(l_clinical_service IN NUMBER) IS
            SELECT cs.id_clinical_service, d.id_dept, ei.dt_first_obs_tstz dt_first_obs_tstz
              FROM episode e, epis_info ei, clinical_service cs, dept d
             WHERE e.id_episode = i_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_dep_clin_serv IS NOT NULL
               AND cs.id_clinical_service = nvl(l_clinical_service, e.id_clinical_service)
               AND e.id_dept = d.id_dept
               AND d.id_institution = i_prof.institution
            UNION
            SELECT cs.id_clinical_service, d.id_dept, ei.dt_first_obs_tstz dt_first_obs_tstz
              FROM episode e, epis_info ei, clinical_service cs, dept d
             WHERE e.id_episode = i_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_dep_clin_serv IS NULL
               AND cs.id_clinical_service = decode(l_clinical_service, -1, e.id_cs_requested, l_clinical_service)
               AND e.id_dept_requested = d.id_dept
               AND d.id_institution = i_prof.institution
            UNION
            SELECT NULL id_clinical_service, d.id_dept, ei.dt_first_obs_tstz dt_first_obs_tstz
              FROM epis_info ei, room r, dept d, department dep
             WHERE ei.id_episode = i_episode
               AND ei.id_dep_clin_serv IS NULL
               AND ei.id_room = r.id_room
               AND r.id_department = dep.id_department
               AND dep.id_dept = d.id_dept;
    
        CURSOR c_triage_color IS
            SELECT ei.triage_acuity acuity, ei.triage_rank_acuity rank_acuity, ei.triage_color_text, ei.id_triage_color
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
    
        CURSOR c_shortcut(i_shortcut_name IN VARCHAR2) IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = i_shortcut_name
               AND id_software = i_prof.software
               AND id_institution IN (i_prof.institution, 0)
             ORDER BY id_institution DESC;
    
        l_shortcut_transport VARCHAR2(50 CHAR) := 'GRID_TRANSPORT';
        l_shortcut_image     VARCHAR2(50 CHAR) := 'GRID_IMAGE';
    
        l_id_shortcut_transport sys_shortcut.id_sys_shortcut%TYPE;
        l_id_shortcut_image     sys_shortcut.id_sys_shortcut%TYPE;
    
        l_flg_referral exam_req_det.flg_referral%TYPE;
        l_flg_status_r VARCHAR(2 CHAR);
    
        l_grid_task_img grid_task_img%ROWTYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_exam_req_det IS NULL
           OR i_flg_type != pk_exam_constant.g_type_img
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'PK_IMAGE_TECH.SET_EXAM_GRID_TASK / i_exam_req_det is null';
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_grid_task_img.id_patient,
                 l_grid_task_img.pat_gender,
                 l_grid_task_img.pat_age,
                 l_grid_task_img.num_clin_record;
        CLOSE c_patient;
    
        l_grid_task_img.id_episode := i_episode;
    
        g_error := 'OPEN C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_grid_task_img.id_epis_type,
                 l_grid_task_img.flg_status_epis,
                 l_grid_task_img.id_clinical_service,
                 l_grid_task_img.id_software;
        CLOSE c_episode;
    
        g_error := 'OPEN C_EPIS_INFO';
        OPEN c_epis_info(l_grid_task_img.id_clinical_service);
        FETCH c_epis_info
            INTO l_grid_task_img.id_clinical_service, l_grid_task_img.id_dept, l_grid_task_img.dt_first_obs_tstz;
        CLOSE c_epis_info;
    
        g_error := 'OPEN C_TRIAGE_COLOR';
        OPEN c_triage_color;
        FETCH c_triage_color
            INTO l_grid_task_img.acuity,
                 l_grid_task_img.rank_acuity,
                 l_grid_task_img.triage_color_text,
                 l_grid_task_img.id_triage_color;
        CLOSE c_triage_color;
    
        g_error                 := 'OPEN C_SHORTCUT';
        l_id_shortcut_transport := NULL;
        OPEN c_shortcut(l_shortcut_transport);
        FETCH c_shortcut
            INTO l_id_shortcut_transport;
        CLOSE c_shortcut;
        l_id_shortcut_transport := nvl(l_id_shortcut_transport, '0');
    
        l_id_shortcut_image := NULL;
        OPEN c_shortcut(l_shortcut_image);
        FETCH c_shortcut
            INTO l_id_shortcut_image;
        CLOSE c_shortcut;
        l_id_shortcut_image := nvl(l_id_shortcut_image, '0');
    
        g_error := 'OPEN C_EXAM_REQ';
        OPEN c_exam_req;
        FETCH c_exam_req
            INTO l_grid_task_img.id_exam,
                 l_flg_referral,
                 l_grid_task_img.id_exam_cat,
                 l_grid_task_img.id_professional,
                 l_grid_task_img.id_episode,
                 l_grid_task_img.id_institution,
                 l_grid_task_img.dt_begin_tstz,
                 l_grid_task_img.dt_req_tstz,
                 l_grid_task_img.dt_pend_req_tstz,
                 l_grid_task_img.dt_schedule_tstz,
                 l_grid_task_img.flg_time_req,
                 l_grid_task_img.flg_status_req_det,
                 l_grid_task_img.id_room,
                 l_grid_task_img.flg_status_mov,
                 l_grid_task_img.dt_req_mov_tstz,
                 l_grid_task_img.dt_end_mov_tstz,
                 l_flg_status_r,
                 l_grid_task_img.id_task_dependency,
                 l_grid_task_img.flg_req_origin_module,
                 l_grid_task_img.id_announced_arrival;
        g_found := c_exam_req%FOUND;
        CLOSE c_exam_req;
    
        IF NOT g_found
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'PK_IMAGE_TECH.SET_EXAM_GRID_TASK / ' || g_error;
            RAISE g_other_exception;
        END IF;
    
        g_error := 'REQUEST';
        IF l_grid_task_img.flg_status_req_det IN
           (pk_exam_constant.g_exam_req,
            pk_exam_constant.g_exam_wtg_tde,
            pk_exam_constant.g_exam_pending,
            pk_exam_constant.g_exam_efectiv,
            pk_exam_constant.g_exam_tosched)
           AND (l_grid_task_img.flg_status_mov != pk_alert_constant.g_mov_status_transp OR
           l_grid_task_img.flg_status_mov IS NULL)
        THEN
            l_grid_task_img.request := l_id_shortcut_image ||
                                       pk_utils.get_status_string(i_lang,
                                                                  i_prof,
                                                                  pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            l_grid_task_img.flg_status_req_det,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            l_grid_task_img.dt_req_tstz,
                                                                                                            l_grid_task_img.dt_pend_req_tstz,
                                                                                                            l_grid_task_img.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            l_grid_task_img.flg_status_req_det,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            l_grid_task_img.dt_req_tstz,
                                                                                                            l_grid_task_img.dt_pend_req_tstz,
                                                                                                            l_grid_task_img.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                                             i_prof,
                                                                                                             l_grid_task_img.id_episode,
                                                                                                             l_grid_task_img.flg_time_req,
                                                                                                             l_grid_task_img.flg_status_req_det,
                                                                                                             l_flg_referral,
                                                                                                             l_flg_status_r,
                                                                                                             l_grid_task_img.dt_req_tstz,
                                                                                                             l_grid_task_img.dt_pend_req_tstz,
                                                                                                             l_grid_task_img.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            l_grid_task_img.flg_status_req_det,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            l_grid_task_img.dt_req_tstz,
                                                                                                            l_grid_task_img.dt_pend_req_tstz,
                                                                                                            l_grid_task_img.dt_begin_tstz));
        ELSE
            g_error := 'TRANSPORT';
            IF l_grid_task_img.flg_status_mov = pk_alert_constant.g_mov_status_transp
            THEN
                l_grid_task_img.transport := l_id_shortcut_transport ||
                                             pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                                                  i_prof,
                                                                                                                  l_grid_task_img.id_episode,
                                                                                                                  l_grid_task_img.flg_time_req,
                                                                                                                  l_grid_task_img.flg_status_req_det,
                                                                                                                  l_flg_referral,
                                                                                                                  l_flg_status_r,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz),
                                                                        pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                                                  i_prof,
                                                                                                                  l_grid_task_img.id_episode,
                                                                                                                  l_grid_task_img.flg_time_req,
                                                                                                                  l_grid_task_img.flg_status_req_det,
                                                                                                                  l_flg_referral,
                                                                                                                  l_flg_status_r,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz),
                                                                        pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   l_grid_task_img.id_episode,
                                                                                                                   l_grid_task_img.flg_time_req,
                                                                                                                   l_grid_task_img.flg_status_req_det,
                                                                                                                   l_flg_referral,
                                                                                                                   l_flg_status_r,
                                                                                                                   l_grid_task_img.dt_req_mov_tstz,
                                                                                                                   l_grid_task_img.dt_req_mov_tstz,
                                                                                                                   l_grid_task_img.dt_req_mov_tstz),
                                                                        pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                                                  i_prof,
                                                                                                                  l_grid_task_img.id_episode,
                                                                                                                  l_grid_task_img.flg_time_req,
                                                                                                                  l_grid_task_img.flg_status_req_det,
                                                                                                                  l_flg_referral,
                                                                                                                  l_flg_status_r,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz,
                                                                                                                  l_grid_task_img.dt_req_mov_tstz));
            
            ELSE
                l_grid_task_img.request := NULL;
            END IF;
        END IF;
    
        g_error := 'EXECUTE';
        IF l_grid_task_img.flg_status_req_det = pk_exam_constant.g_exam_toexec
        THEN
            l_grid_task_img.execute := l_id_shortcut_image ||
                                       pk_utils.get_status_string(i_lang,
                                                                  i_prof,
                                                                  pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            pk_exam_constant.g_exam_req,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz),
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz),
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz)),
                                                                  pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            pk_exam_constant.g_exam_req,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz),
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz),
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz)),
                                                                  pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                                             i_prof,
                                                                                                             l_grid_task_img.id_episode,
                                                                                                             l_grid_task_img.flg_time_req,
                                                                                                             pk_exam_constant.g_exam_req,
                                                                                                             l_flg_referral,
                                                                                                             l_flg_status_r,
                                                                                                             greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                          l_grid_task_img.dt_req_tstz),
                                                                                                                      l_grid_task_img.dt_req_tstz),
                                                                                                             greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                          l_grid_task_img.dt_req_tstz),
                                                                                                                      l_grid_task_img.dt_req_tstz),
                                                                                                             greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                          l_grid_task_img.dt_req_tstz),
                                                                                                                      l_grid_task_img.dt_req_tstz)),
                                                                  pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            pk_exam_constant.g_exam_req,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz),
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz),
                                                                                                            greatest(nvl(l_grid_task_img.dt_end_mov_tstz,
                                                                                                                         l_grid_task_img.dt_req_tstz),
                                                                                                                     l_grid_task_img.dt_req_tstz)));
        
        ELSIF l_grid_task_img.flg_status_req_det = pk_exam_constant.g_exam_exec
        THEN
            l_grid_task_img.execute := l_id_shortcut_image ||
                                       pk_utils.get_status_string(i_lang,
                                                                  i_prof,
                                                                  pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            l_grid_task_img.flg_status_req_det,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            l_grid_task_img.dt_req_tstz,
                                                                                                            l_grid_task_img.dt_pend_req_tstz,
                                                                                                            l_grid_task_img.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            l_grid_task_img.flg_status_req_det,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            l_grid_task_img.dt_req_tstz,
                                                                                                            l_grid_task_img.dt_pend_req_tstz,
                                                                                                            l_grid_task_img.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                                             i_prof,
                                                                                                             l_grid_task_img.id_episode,
                                                                                                             l_grid_task_img.flg_time_req,
                                                                                                             l_grid_task_img.flg_status_req_det,
                                                                                                             l_flg_referral,
                                                                                                             l_flg_status_r,
                                                                                                             l_grid_task_img.dt_req_tstz,
                                                                                                             l_grid_task_img.dt_pend_req_tstz,
                                                                                                             l_grid_task_img.dt_begin_tstz),
                                                                  pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                                            i_prof,
                                                                                                            l_grid_task_img.id_episode,
                                                                                                            l_grid_task_img.flg_time_req,
                                                                                                            l_grid_task_img.flg_status_req_det,
                                                                                                            l_flg_referral,
                                                                                                            l_flg_status_r,
                                                                                                            l_grid_task_img.dt_req_tstz,
                                                                                                            l_grid_task_img.dt_pend_req_tstz,
                                                                                                            l_grid_task_img.dt_begin_tstz));
        END IF;
    
        g_error := 'COMPLETE';
        IF l_grid_task_img.flg_status_req_det = pk_exam_constant.g_exam_result
        THEN
            l_grid_task_img.complete := l_id_shortcut_image ||
                                        pk_utils.get_status_string(i_lang,
                                                                   i_prof,
                                                                   pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                                             i_prof,
                                                                                                             l_grid_task_img.id_episode,
                                                                                                             l_grid_task_img.flg_time_req,
                                                                                                             l_grid_task_img.flg_status_req_det,
                                                                                                             l_flg_referral,
                                                                                                             l_flg_status_r,
                                                                                                             l_grid_task_img.dt_req_tstz,
                                                                                                             l_grid_task_img.dt_pend_req_tstz,
                                                                                                             l_grid_task_img.dt_begin_tstz),
                                                                   pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                                             i_prof,
                                                                                                             l_grid_task_img.id_episode,
                                                                                                             l_grid_task_img.flg_time_req,
                                                                                                             l_grid_task_img.flg_status_req_det,
                                                                                                             l_flg_referral,
                                                                                                             l_flg_status_r,
                                                                                                             l_grid_task_img.dt_req_tstz,
                                                                                                             l_grid_task_img.dt_pend_req_tstz,
                                                                                                             l_grid_task_img.dt_begin_tstz),
                                                                   pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                                              i_prof,
                                                                                                              l_grid_task_img.id_episode,
                                                                                                              l_grid_task_img.flg_time_req,
                                                                                                              l_grid_task_img.flg_status_req_det,
                                                                                                              l_flg_referral,
                                                                                                              l_flg_status_r,
                                                                                                              l_grid_task_img.dt_req_tstz,
                                                                                                              l_grid_task_img.dt_pend_req_tstz,
                                                                                                              l_grid_task_img.dt_begin_tstz),
                                                                   pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                                             i_prof,
                                                                                                             l_grid_task_img.id_episode,
                                                                                                             l_grid_task_img.flg_time_req,
                                                                                                             l_grid_task_img.flg_status_req_det,
                                                                                                             l_flg_referral,
                                                                                                             l_flg_status_r,
                                                                                                             l_grid_task_img.dt_req_tstz,
                                                                                                             l_grid_task_img.dt_pend_req_tstz,
                                                                                                             l_grid_task_img.dt_begin_tstz));
        END IF;
    
        g_error := 'MERGE INTO GRID_TASK_IMG';
        MERGE INTO grid_task_img gti
        USING (SELECT i_exam_req id_exam_req,
                      i_exam_req_det id_exam_req_det,
                      l_grid_task_img.id_professional id_professional,
                      l_grid_task_img.id_patient id_patient,
                      l_grid_task_img.pat_age pat_age,
                      l_grid_task_img.pat_gender pat_gender,
                      l_grid_task_img.num_clin_record num_clin_record,
                      l_grid_task_img.id_episode id_episode,
                      decode(l_grid_task_img.id_episode, NULL, NULL, l_grid_task_img.id_epis_type) id_epis_type,
                      decode(l_grid_task_img.id_episode, NULL, NULL, l_grid_task_img.flg_status_epis) flg_status_epis,
                      l_grid_task_img.id_dept id_dept,
                      l_grid_task_img.id_clinical_service id_clinical_service,
                      nvl(l_grid_task_img.id_software, i_prof.software) id_software,
                      nvl(l_grid_task_img.id_institution, i_prof.institution) id_institution,
                      l_grid_task_img.dt_first_obs_tstz dt_first_obs_tstz,
                      l_grid_task_img.id_exam id_exam,
                      l_grid_task_img.id_exam_cat id_exam_cat,
                      l_grid_task_img.dt_req_tstz dt_req_tstz,
                      l_grid_task_img.dt_begin_tstz dt_begin_tstz,
                      l_grid_task_img.dt_pend_req_tstz dt_pend_req_tstz,
                      l_grid_task_img.dt_schedule_tstz dt_schedule_tstz,
                      l_grid_task_img.flg_time_req flg_time_req,
                      l_grid_task_img.flg_status_req_det flg_status_req_det,
                      l_grid_task_img.id_room id_room,
                      l_grid_task_img.flg_status_mov flg_status_mov,
                      l_grid_task_img.dt_req_mov_tstz dt_req_mov_tstz,
                      l_grid_task_img.dt_end_mov_tstz dt_end_mov_tstz,
                      l_grid_task_img.acuity acuity,
                      l_grid_task_img.rank_acuity rank_acuity,
                      l_grid_task_img.triage_color_text triage_color_text,
                      l_grid_task_img.id_triage_color id_triage_color,
                      l_grid_task_img.request request,
                      l_grid_task_img.transport transport,
                      l_grid_task_img.execute EXECUTE,
                      l_grid_task_img.complete complete,
                      l_grid_task_img.id_task_dependency id_task_dependency,
                      l_grid_task_img.flg_req_origin_module flg_req_origin_module,
                      l_grid_task_img.id_announced_arrival id_announced_arrival
                 FROM dual) t
        ON (gti.id_exam_req = t.id_exam_req AND gti.id_exam_req_det = t.id_exam_req_det)
        WHEN MATCHED THEN
            UPDATE
               SET id_professional       = t.id_professional,
                   id_patient            = t.id_patient,
                   pat_age               = t.pat_age,
                   pat_gender            = t.pat_gender,
                   num_clin_record       = t.num_clin_record,
                   id_episode            = t.id_episode,
                   id_epis_type          = t.id_epis_type,
                   flg_status_epis       = t.flg_status_epis,
                   id_dept               = nvl(t.id_dept, gti.id_dept),
                   id_clinical_service   = t.id_clinical_service,
                   id_software           = t.id_software,
                   id_institution        = t.id_institution,
                   dt_first_obs_tstz     = t.dt_first_obs_tstz,
                   id_exam               = t.id_exam,
                   id_exam_cat           = t.id_exam_cat,
                   dt_req_tstz           = t.dt_req_tstz,
                   dt_begin_tstz         = t.dt_begin_tstz,
                   dt_pend_req_tstz      = t.dt_pend_req_tstz,
                   dt_schedule_tstz      = t.dt_schedule_tstz,
                   flg_time_req          = t.flg_time_req,
                   flg_status_req_det    = t.flg_status_req_det,
                   id_room               = t.id_room,
                   flg_status_mov        = t.flg_status_mov,
                   dt_req_mov_tstz       = t.dt_req_mov_tstz,
                   dt_end_mov_tstz       = t.dt_end_mov_tstz,
                   acuity                = t.acuity,
                   rank_acuity           = t.rank_acuity,
                   triage_color_text     = t.triage_color_text,
                   id_triage_color       = t.id_triage_color,
                   request               = t.request,
                   transport             = t.transport,
                   EXECUTE               = t.execute,
                   complete              = t.complete,
                   id_task_dependency    = t.id_task_dependency,
                   flg_req_origin_module = t.flg_req_origin_module,
                   id_announced_arrival  = t.id_announced_arrival
        WHEN NOT MATCHED THEN
            INSERT
                (id_exam_req,
                 id_exam_req_det,
                 id_professional,
                 id_patient,
                 pat_age,
                 pat_gender,
                 num_clin_record,
                 id_episode,
                 id_epis_type,
                 flg_status_epis,
                 id_dept,
                 id_clinical_service,
                 id_software,
                 id_institution,
                 dt_first_obs_tstz,
                 id_exam,
                 id_exam_cat,
                 dt_req_tstz,
                 dt_begin_tstz,
                 dt_pend_req_tstz,
                 dt_schedule_tstz,
                 flg_time_req,
                 flg_status_req_det,
                 id_room,
                 flg_status_mov,
                 dt_req_mov_tstz,
                 dt_end_mov_tstz,
                 acuity,
                 rank_acuity,
                 triage_color_text,
                 id_triage_color,
                 request,
                 transport,
                 EXECUTE,
                 complete,
                 id_task_dependency,
                 flg_req_origin_module,
                 id_announced_arrival)
            VALUES
                (t.id_exam_req,
                 t.id_exam_req_det,
                 t.id_professional,
                 t.id_patient,
                 t.pat_age,
                 t.pat_gender,
                 t.num_clin_record,
                 t.id_episode,
                 t.id_epis_type,
                 t.flg_status_epis,
                 t.id_dept,
                 t.id_clinical_service,
                 t.id_software,
                 t.id_institution,
                 t.dt_first_obs_tstz,
                 t.id_exam,
                 t.id_exam_cat,
                 t.dt_req_tstz,
                 t.dt_begin_tstz,
                 t.dt_pend_req_tstz,
                 t.dt_schedule_tstz,
                 t.flg_time_req,
                 t.flg_status_req_det,
                 t.id_room,
                 t.flg_status_mov,
                 t.dt_req_mov_tstz,
                 t.dt_end_mov_tstz,
                 t.acuity,
                 t.rank_acuity,
                 t.triage_color_text,
                 t.id_triage_color,
                 t.request,
                 t.transport,
                 t.execute,
                 t.complete,
                 t.id_task_dependency,
                 t.flg_req_origin_module,
                 t.id_announced_arrival);
    
        DELETE grid_task_img gti
         WHERE gti.id_exam_req_det = i_exam_req_det
           AND l_grid_task_img.id_epis_type != pk_exam_constant.g_episode_type_rad
           AND (gti.flg_status_req_det IN (pk_exam_constant.g_exam_predefined,
                                           pk_exam_constant.g_exam_draft,
                                           pk_exam_constant.g_exam_sos,
                                           pk_exam_constant.g_exam_exterior,
                                           pk_exam_constant.g_exam_read,
                                           pk_exam_constant.g_exam_cancel) OR
               (gti.flg_status_req_det = pk_exam_constant.g_exam_result AND
               gti.id_software = pk_alert_constant.g_soft_outpatient) OR
               (gti.flg_status_req_det = pk_exam_constant.g_exam_result AND
               gti.flg_status_epis = pk_alert_constant.g_epis_status_pendent) OR
               (l_flg_referral IN (pk_exam_constant.g_flg_referral_r,
                                    pk_exam_constant.g_flg_referral_s,
                                    pk_exam_constant.g_flg_referral_i)));
    
        IF l_grid_task_img.id_epis_type != pk_exam_constant.g_episode_type_rad
           AND l_grid_task_img.flg_status_epis = pk_alert_constant.g_epis_status_inactive
        THEN
            DELETE grid_task_img gti
             WHERE gti.id_episode = l_grid_task_img.id_episode;
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
                                              'SET_EXAM_GRID_TASK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_exam_grid_task;

    PROCEDURE set_exam_episode_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_id_exam_req     exam_req.id_exam_req%TYPE;
        l_id_exam_req_det exam_req_det.id_exam_req_det%TYPE;
        l_flg_status      episode.flg_status%TYPE;
    
        CURSOR c_grid_task IS
            SELECT /*+ opt_estimate(table e rows=1) */
             gti.id_exam_req, gti.id_exam_req_det, e.flg_status
              FROM grid_task_img gti
              JOIN episode e
                ON e.id_episode = gti.id_episode
             WHERE e.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                column_value
                                 FROM TABLE(i_rowids) t);
    
    BEGIN
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'EPISODE',
                                                 i_expected_dg_table_name => 'GRID_TASK_IMG',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => table_varchar('FLG_STATUS'))
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF i_event_type = t_data_gov_mnt.g_event_update
        THEN
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
            
                OPEN c_grid_task;
                LOOP
                    FETCH c_grid_task
                        INTO l_id_exam_req, l_id_exam_req_det, l_flg_status;
                    EXIT WHEN c_grid_task%NOTFOUND;
                
                    UPDATE grid_task_img gti
                       SET gti.flg_status_epis = l_flg_status
                     WHERE gti.id_exam_req = l_id_exam_req
                       AND gti.id_exam_req_det = l_id_exam_req_det;
                END LOOP;
                CLOSE c_grid_task;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_exam_episode_status;

    FUNCTION get_technician_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat_type category.flg_type%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_num_days_back sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK',
                                                                         i_prof);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
    
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
    
        DELETE grid_task_img gti
         WHERE gti.flg_status_req_det = pk_exam_constant.g_exam_result
           AND gti.dt_req_tstz <= l_dt_begin - INTERVAL '1'
         DAY
           AND gti.id_epis_type != pk_exam_constant.g_episode_type_rad;
    
        DELETE grid_task_img gti
         WHERE gti.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gti.id_epis_type != pk_exam_constant.g_episode_type_rad;
    
        l_num_days_back := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        DELETE grid_task_img gti
         WHERE gti.flg_status_req_det IN
               (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
           AND gti.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
           AND gti.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gti.id_epis_type = pk_exam_constant.g_episode_type_rad;
    
        COMMIT;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT gti.acuity,
                   gti.rank_acuity,
                   gti.triage_color_text color,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, gti.id_episode, gti.id_triage_color)
                      FROM dual) esi_level,
                   gti.id_epis_type,
                   (SELECT pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.' || gti.id_software)
                      FROM dual) epis_type,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'AB_INSTITUTION.CODE_INSTITUTION.' || gti.id_institution)
                      FROM dual) desc_institution,
                   (SELECT pk_date_utils.date_send_tsz(i_lang, gti.dt_first_obs_tstz, i_prof)
                      FROM dual) dt_first_obs,
                   (SELECT pk_patient.get_pat_name(i_lang, i_prof, gti.id_patient, gti.id_episode, NULL)
                      FROM dual) desc_patient,
                   (SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || gti.id_exam, NULL)
                      FROM dual) desc_exam,
                   gti.request col_request,
                   gti.transport col_transport,
                   gti.execute col_execute,
                   gti.complete col_complete,
                   gti.id_patient,
                   gti.id_exam,
                   gti.id_exam_req_det,
                   gti.id_episode,
                   gti.flg_status_req_det,
                   gti.id_software,
                   g_sysdate_char dt_server
              FROM grid_task_img gti
             WHERE ((gti.flg_time_req = pk_exam_constant.g_flg_time_e AND
                   gti.flg_status_epis NOT IN (pk_alert_constant.g_inactive, pk_alert_constant.g_cancelled)) OR
                   gti.flg_time_req IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d) AND
                   gti.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end AND
                   gti.flg_status_req_det NOT IN (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched) OR
                   (gti.flg_time_req = pk_exam_constant.g_flg_time_n AND gti.id_episode IS NOT NULL AND
                   gti.flg_status_req_det != pk_exam_constant.g_exam_pending))
               AND (EXISTS
                    (SELECT 1
                       FROM institution i
                      WHERE i.id_parent = (SELECT i.id_parent
                                             FROM institution i
                                            WHERE i.id_institution = i_prof.institution)
                        AND i.id_institution = gti.id_institution) OR gti.id_institution = i_prof.institution OR
                    (gti.id_institution != i_prof.institution AND EXISTS
                     (SELECT 1
                        FROM transfer_institution ti
                       WHERE ti.flg_status = pk_alert_constant.g_flg_status_f
                         AND ti.id_episode = gti.id_episode
                         AND ti.id_institution_dest = i_prof.institution)))
               AND EXISTS
             (SELECT 1
                      FROM prof_room pr
                     WHERE id_professional = i_prof.id
                       AND pr.id_room = gti.id_room)
               AND ((instr(nvl((SELECT flg_first_result
                                 FROM exam_dep_clin_serv e
                                WHERE e.id_exam = gti.id_exam
                                  AND e.flg_type = pk_exam_constant.g_exam_can_req
                                  AND e.id_software = gti.id_software
                                  AND e.id_institution = gti.id_institution),
                               '#'),
                           l_prof_cat_type) != 0) OR l_prof_cat_type != pk_alert_constant.g_cat_type_technician)
            UNION ALL
            SELECT gti.acuity,
                   gti.rank_acuity,
                   gti.triage_color_text color,
                   (SELECT pk_edis_triage.get_epis_esi_level(i_lang, i_prof, gti.id_episode, gti.id_triage_color)
                      FROM dual) esi_level,
                   gti.id_epis_type,
                   (SELECT pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.' || gti.id_software)
                      FROM dual) epis_type,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'AB_INSTITUTION.CODE_INSTITUTION.' || gti.id_institution)
                      FROM dual) desc_institution,
                   (SELECT pk_date_utils.date_send_tsz(i_lang, gti.dt_first_obs_tstz, i_prof)
                      FROM dual) dt_first_obs,
                   (SELECT pk_patient.get_pat_name(i_lang, i_prof, gti.id_patient, gti.id_episode, NULL)
                      FROM dual) desc_patient,
                   (SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || gti.id_exam, NULL)
                      FROM dual) desc_exam,
                   gti.request col_request,
                   gti.transport col_transport,
                   gti.execute col_execute,
                   gti.complete col_complete,
                   gti.id_patient,
                   gti.id_exam,
                   gti.id_exam_req_det,
                   gti.id_episode,
                   gti.flg_status_req_det,
                   gti.id_software,
                   g_sysdate_char dt_server
              FROM grid_task_img gti, episode e
             WHERE (gti.flg_time_req = pk_exam_constant.g_flg_time_e AND
                   gti.flg_status_epis = pk_alert_constant.g_inactive)
               AND (EXISTS
                    (SELECT 1
                       FROM institution i
                      WHERE i.id_parent = (SELECT i.id_parent
                                             FROM institution i
                                            WHERE i.id_institution = i_prof.institution)
                        AND i.id_institution = gti.id_institution) OR gti.id_institution = i_prof.institution OR
                    (gti.id_institution != i_prof.institution AND EXISTS
                     (SELECT 1
                        FROM transfer_institution ti
                       WHERE ti.flg_status = pk_alert_constant.g_flg_status_f
                         AND ti.id_episode = gti.id_episode
                         AND ti.id_institution_dest = i_prof.institution)))
               AND EXISTS
             (SELECT 1
                      FROM prof_room pr
                     WHERE id_professional = i_prof.id
                       AND pr.id_room = gti.id_room)
               AND ((instr(nvl((SELECT flg_first_result
                                 FROM exam_dep_clin_serv e
                                WHERE e.id_exam = gti.id_exam
                                  AND e.flg_type = pk_exam_constant.g_exam_can_req
                                  AND e.id_software = gti.id_software
                                  AND e.id_institution = gti.id_institution),
                               '#'),
                           l_prof_cat_type) != 0) OR l_prof_cat_type != pk_alert_constant.g_cat_type_technician)
               AND gti.id_episode = e.id_prev_episode
             ORDER BY rank_acuity, desc_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TECHNICIAN_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_technician_grid;

    FUNCTION get_exam_to_schedule_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_order sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'EXAMS_T239');
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT gti.id_exam_req,
                   gti.id_exam,
                   gti.flg_status_req_det flg_status,
                   (SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || gti.id_exam, NULL)
                      FROM dual) desc_exam,
                   decode(eea.notes_scheduler, NULL, pk_exam_constant.g_no, pk_exam_constant.g_yes) flg_notes,
                   (SELECT pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.' || gti.id_software)
                      FROM dual) epis_type,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'AB_INSTITUTION.CODE_INSTITUTION.' || gti.id_institution)
                      FROM dual) desc_institution,
                   l_msg_order || ' ' || gti.id_exam_req num_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eea.id_prof_req) prof_name,
                   pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(eea.id_prof_req, gti.id_software, gti.id_institution)) desc_speciality,
                   decode(gti.flg_status_req_det,
                          pk_exam_constant.g_exam_tosched,
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     '|' || pk_alert_constant.g_display_type_date_icon || '|' ||
                                                     pk_date_utils.to_char_insttimezone(i_prof,
                                                                                        eea.dt_req,
                                                                                        pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) ||
                                                     '||#|' || pk_alert_constant.g_color_red || '||||&|Y',
                                                     '',
                                                     'EXAM_REQ_DET.FLG_STATUS',
                                                     pk_exam_constant.g_exam_pending),
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     eea.status_str,
                                                     eea.status_msg,
                                                     eea.status_icon,
                                                     eea.status_flg)) status_string,
                   pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', gti.flg_status_req_det) rank,
                   pk_date_utils.date_send_tsz(i_lang, nvl(eea.dt_begin, eea.dt_req), i_prof) dt_ord
              FROM grid_task_img gti, exams_ea eea
             WHERE gti.id_patient = i_patient
               AND gti.flg_time_req IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
               AND gti.flg_status_req_det IN (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched)
               AND (EXISTS
                    (SELECT 1
                       FROM institution i
                      WHERE i.id_parent = (SELECT i.id_parent
                                             FROM institution i
                                            WHERE i.id_institution = i_prof.institution)
                        AND i.id_institution = gti.id_institution) OR gti.id_institution = i_prof.institution OR
                    (gti.id_institution != i_prof.institution AND EXISTS
                     (SELECT 1
                        FROM transfer_institution ti
                       WHERE ti.flg_status = pk_alert_constant.g_flg_status_f
                         AND ti.id_episode = gti.id_episode
                         AND ti.id_institution_dest = i_prof.institution)))
               AND EXISTS (SELECT 1
                      FROM prof_room pr
                     WHERE id_professional = i_prof.id
                       AND pr.id_room = gti.id_room)
               AND gti.id_exam_req_det = eea.id_exam_req_det
             ORDER BY rank, dt_ord;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_TO_SCHEDULE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_to_schedule_list;

    FUNCTION get_epis_active_itech
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where     VARCHAR2(4300);
        l_from      VARCHAR2(4300);
        v_from_cond VARCHAR2(4000);
    
        l_ret BOOLEAN;
    
    BEGIN
    
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        l_where := NULL;
    
        g_error := 'GET WHERE';
        IF NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   o_where    => l_where)
        THEN
            l_where := NULL;
        END IF;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                g_error := 'CALL PK_SEARCH.GET_FROM_CONDITION';
                IF NOT pk_search.get_from_condition(i_lang,
                                                    i_prof,
                                                    i_id_sys_btn_crit(i),
                                                    REPLACE(i_crit_val(i), '''', '%'),
                                                    v_from_cond,
                                                    o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
                l_from := l_from || v_from_cond;
            END IF;
        END LOOP;
    
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT *
              FROM TABLE(tf_epis_active_itech(i_lang, i_prof, l_where, l_from));
    
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
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_list);
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_ACTIVE_ITECH', o_error);
        
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_list);
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_ACTIVE_ITECH', o_error);
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_ACTIVE_ITECH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_active_itech;

    FUNCTION tf_epis_active_itech
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2
    ) RETURN t_coll_episactiveitech IS
    
        l_sql   VARCHAR2(4000);
        dataset pk_types.cursor_type;
        l_limit sys_config.desc_sys_config%TYPE;
        out_obj t_rec_episactiveitech := t_rec_episactiveitech(NULL,
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
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL,
                                                               NULL);
    
        TYPE dataset_tt IS TABLE OF v_src_itech_active%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset   dataset_tt;
        l_row       PLS_INTEGER := 1;
        RESULT      t_coll_episactiveitech := t_coll_episactiveitech();
        l_dt_server VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
    
        pk_context_api.set_parameter('g_epis_active', pk_alert_constant.g_epis_status_active);
        pk_context_api.set_parameter('g_epis_pending', pk_alert_constant.g_epis_status_pendent);
        pk_context_api.set_parameter('itech_software', pk_sysconfig.get_config('SOFTWARE_ID_ITECH', i_prof));
        pk_context_api.set_parameter('exams_software', pk_sysconfig.get_config('SOFTWARE_ID_EXAMS', i_prof));
        pk_context_api.set_parameter('l_search_concluded',
                                     pk_sysconfig.get_config('TECHNICIAN_PATIENT_SEARCH', i_prof));
    
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
    
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
    
        g_error := 'OPEN CURSOR';
        IF i_from IS NOT NULL
        THEN
            l_sql := 'SELECT /*+opt_estimate(table pat rows=1)*/ t.* FROM v_src_itech_active t, ' || i_from || --
                     ' WHERE rownum <= :l_limit + 1 ' || --
                     ' AND t.id_patient = pat.id_patient ' || i_where || ' ' || --
                     ' ORDER BY pat.position, t.flg_status, t.code_exam';
        ELSE
            l_sql := 'SELECT * FROM v_src_itech_active t WHERE rownum <= :l_limit + 1 ' || i_where || ' ' || --
                     ' ORDER BY t.order_name, t.flg_status, t.code_exam';
        END IF;
    
        g_error := 'OPEN DATASET';
        OPEN dataset FOR l_sql
            USING l_limit;
    
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
    
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
    
        l_dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        WHILE (l_row <= result.count AND l_row <= l_limit)
        LOOP
            out_obj.rank             := l_dataset(l_row).rank;
            out_obj.acuity           := CASE l_dataset(l_row).id_software
                                            WHEN pk_alert_constant.g_soft_edis THEN
                                             nvl(l_dataset(l_row).color, pk_alert_constant.g_color_icon_medium_grey)
                                            ELSE
                                             l_dataset(l_row).color
                                        END;
            out_obj.rank_acuity := CASE l_dataset(l_row).id_software
                                       WHEN pk_alert_constant.g_soft_edis THEN
                                        CASE
                                            WHEN out_obj.rank IS NULL THEN
                                             CASE l_dataset(l_row).id_software
                                                 WHEN pk_alert_constant.g_soft_edis THEN
                                                  900
                                                 ELSE
                                                  999
                                             END
                                            ELSE
                                             out_obj.rank
                                        END
                                       ELSE
                                        NULL
                                   END;
            out_obj.epis_type        := pk_translation.get_translation(i_lang,
                                                                       'AB_SOFTWARE.CODE_SOFTWARE.' || l_dataset(l_row).id_software);
            out_obj.desc_institution := pk_translation.get_translation(i_lang,
                                                                       'AB_INSTITUTION.CODE_INSTITUTION.' || l_dataset(l_row).id_institution);
            out_obj.dt_first_obs     := CASE l_dataset(l_row).dt_first_obs_tstz
                                            WHEN NULL THEN
                                             NULL
                                            ELSE
                                             pk_date_utils.date_send_tsz(i_lang,
                                                                         l_dataset(l_row).dt_first_obs_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software)
                                        END;
            out_obj.desc_patient     := l_dataset(l_row).name_pat;
            out_obj.pat_ndo          := l_dataset(l_row).pat_ndo;
            out_obj.pat_nd_icon      := l_dataset(l_row).pat_nd_icon;
            out_obj.id_patient       := l_dataset(l_row).id_patient;
            out_obj.id_episode       := l_dataset(l_row).id_episode;
            out_obj.dt_server        := l_dt_server;
            out_obj.desc_exam        := pk_exams_api_db.get_alias_translation(i_lang,
                                                                              NULL,
                                                                              l_dataset(l_row).code_exam,
                                                                              NULL);
        
            out_obj.priority      := pk_sysdomain.get_domain(i_lang,
                                                             i_prof,
                                                             'EXAM_REQ_DET.FLG_PRIORITY',
                                                             l_dataset(l_row).priority,
                                                             NULL);
            out_obj.col_request   := l_dataset(l_row).request;
            out_obj.col_transport := l_dataset(l_row).transport;
            out_obj.col_execute   := l_dataset(l_row).execute;
            out_obj.col_complete  := l_dataset(l_row).complete;
        
            out_obj.status_string := l_dataset(l_row).status_string;
        
            out_obj.flg_result := l_dataset(l_row).flg_result;
        
            out_obj.contact_state := CASE
                                         WHEN l_dataset(l_row).flg_status = pk_exam_constant.g_exam_cancel THEN
                                          pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_CONTACT', l_dataset(l_row).flg_contact)
                                         ELSE
                                          CASE
                                              WHEN nvl(l_dataset(l_row).id_schedule, -1) = -1 THEN
                                               pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_CONTACT', l_dataset(l_row).flg_contact)
                                              ELSE
                                               pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_STATE', l_dataset(l_row).flg_state)
                                          END
                                     END;
        
            IF (pk_transfer_institution.check_epis_transfer(l_dataset(l_row).id_episode) = 0)
            THEN
                out_obj.fast_track_icon := pk_fast_track.get_fast_track_icon(i_lang,
                                                                             i_prof,
                                                                             l_dataset(l_row).id_fast_track,
                                                                             pk_alert_constant.g_icon_ft);
            ELSE
                out_obj.fast_track_icon := pk_fast_track.get_fast_track_icon(i_lang,
                                                                             i_prof,
                                                                             l_dataset(l_row).id_fast_track,
                                                                             pk_alert_constant.g_icon_ft_transfer);
            END IF;
        
            IF (l_dataset(l_row).color = pk_alert_constant.g_ft_color)
            THEN
                out_obj.fast_track_color := pk_alert_constant.g_ft_triage_white;
            ELSE
                out_obj.fast_track_color := pk_alert_constant.g_ft_color;
            END IF;
        
            out_obj.fast_track_status := pk_alert_constant.g_ft_status;
        
            IF (NOT l_dataset(l_row).id_fast_track IS NULL)
            THEN
                out_obj.fast_track_desc := pk_fast_track.get_fast_track_desc(i_lang,
                                                                             i_prof,
                                                                             l_dataset(l_row).id_fast_track,
                                                                             pk_alert_constant.g_desc_grid);
            ELSE
                out_obj.fast_track_desc := NULL;
            END IF;
        
            out_obj.gender          := pk_patient.get_gender(i_lang, l_dataset(l_row).gender);
            out_obj.pat_age         := pk_patient.get_pat_age(i_lang,
                                                              l_dataset         (l_row).dt_birth,
                                                              l_dataset         (l_row).age,
                                                              i_prof.institution,
                                                              i_prof.software);
            out_obj.photo           := pk_patphoto.get_pat_photo(i_lang,
                                                                 i_prof,
                                                                 l_dataset(l_row).id_patient,
                                                                 l_dataset(l_row).id_episode,
                                                                 NULL);
            out_obj.num_clin_record := l_dataset(l_row).num_clin_record;
            out_obj.dt_target       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        l_dataset(l_row).dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software);
            out_obj.dept            := pk_translation.get_translation(i_lang,
                                                                      'DEPT.CODE_DEPT.' || l_dataset(l_row).id_dept) ||
                                       ' - ' ||
                                       pk_translation.get_translation(i_lang,
                                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || l_dataset(l_row).id_clinical_service);
        
            out_obj.id_task_dependency := l_dataset(l_row).id_task_dependency;
        
            out_obj.icon_name := pk_sysdomain.get_img(i_lang,
                                                      'EXAM_REQ_DET.FLG_REQ_ORIGIN_MODULE',
                                                      l_dataset(l_row).flg_req_origin_module);
        
            out_obj.order_name := l_dataset(l_row).order_name;
        
            RESULT(l_row) := out_obj;
        
            l_row := l_row + 1;
        END LOOP;
    
        RETURN(RESULT);
    
    END tf_epis_active_itech;

    PROCEDURE init_params_grid
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
    
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_num_days_back sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK',
                                                                         l_prof);
    
        --FILTER_BIND
        l_prof_cat category.flg_type%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        g_sysdate_char VARCHAR(50 CHAR);
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(l_lang, g_sysdate_tstz, l_prof);
    
        l_prof_cat := pk_prof_utils.get_category(l_lang, l_prof);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_cat_type', l_prof_cat);
    
        IF i_context_vals.count > 0
        THEN
            IF i_context_vals(1) = 0
            THEN
                l_epis_type := NULL;
            ELSE
                l_epis_type := i_context_vals(1);
            END IF;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz);
    
        DELETE grid_task_img gti
         WHERE gti.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gti.id_epis_type != pk_exam_constant.g_episode_type_rad;
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        DELETE grid_task_img gti
         WHERE gti.flg_status_req_det IN (pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
           AND gti.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
           AND gti.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gti.id_epis_type = pk_exam_constant.g_episode_type_rad;
    
        COMMIT;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        pk_context_api.set_parameter('i_dt_begin', l_dt_begin);
        pk_context_api.set_parameter('i_dt_end', l_dt_end);
    
        g_error := 'PK_TECH_IMAGE, parameter:' || i_name || ' not found';
        CASE i_name
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_id_i_prof' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_id_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_id_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'current_timestamp_chr' THEN
                o_vc2 := g_sysdate_char;
            WHEN 'l_sysdate_tstz' THEN
                o_tstz := current_timestamp;
            WHEN 'l_epis_type' THEN
                o_vc2 := l_epis_type;
            ELSE
                NULL;
        END CASE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_IMAGE_TECH',
                                              'INIT_PARAMS_GRID',
                                              o_error);
    END init_params_grid;

    PROCEDURE init_params_sched_req
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
    
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_prof_cat category.flg_type%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        g_sysdate_char VARCHAR(50 CHAR);
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(l_lang, g_sysdate_tstz, l_prof);
    
        l_prof_cat := pk_prof_utils.get_category(l_lang, l_prof);
    
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
    
        g_error := 'PK_TECH_IMAGE, parameter:' || i_name || ' not found';
        CASE i_name
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_prof_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_prof_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_current_timestamp' THEN
                o_vc2 := g_sysdate_tstz;
            ELSE
                NULL;
        END CASE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_IMAGE_TECH',
                                              'INIT_PARAMS_GRID',
                                              o_error);
    END init_params_sched_req;

    FUNCTION get_col_request
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_status_req_det IN exam_req_det.flg_status%TYPE,
        i_flg_status_mov     IN movement.flg_status%TYPE,
        i_flg_time_req       IN exam_req.flg_time%TYPE,
        i_flg_referral       IN exam_req_det.flg_referral%TYPE,
        i_flg_status_r       IN result_status.value%TYPE,
        i_dt_req_tstz        IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz   IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin_tstz      IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_shortcut(i_shortcut_name IN VARCHAR2) IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = i_shortcut_name
               AND id_software = i_prof.software
               AND id_institution IN (i_prof.institution, 0)
             ORDER BY id_institution DESC;
    
        l_id_shortcut_image sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_image    VARCHAR2(50 CHAR) := 'GRID_IMAGE';
    
        l_ret VARCHAR2(100);
    
    BEGIN
    
        l_id_shortcut_image := NULL;
        OPEN c_shortcut(l_shortcut_image);
        FETCH c_shortcut
            INTO l_id_shortcut_image;
        CLOSE c_shortcut;
        l_id_shortcut_image := nvl(l_id_shortcut_image, '0');
    
        SELECT CASE
                   WHEN i_flg_status_req_det IN (pk_exam_constant.g_exam_req,
                                                 pk_exam_constant.g_exam_wtg_tde,
                                                 pk_exam_constant.g_exam_pending,
                                                 pk_exam_constant.g_exam_efectiv)
                        AND (i_flg_status_mov != pk_alert_constant.g_mov_status_transp OR i_flg_status_mov IS NULL) THEN
                    l_id_shortcut_image ||
                    pk_utils.get_status_string(i_lang,
                                               i_prof,
                                               pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_tstz,
                                                                                         i_dt_pend_req_tstz,
                                                                                         i_dt_begin_tstz),
                                               pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_tstz,
                                                                                         i_dt_pend_req_tstz,
                                                                                         i_dt_begin_tstz),
                                               pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                          i_prof,
                                                                                          i_id_episode,
                                                                                          i_flg_time_req,
                                                                                          i_flg_status_req_det,
                                                                                          i_flg_referral,
                                                                                          i_flg_status_r,
                                                                                          i_dt_req_tstz,
                                                                                          i_dt_pend_req_tstz,
                                                                                          i_dt_begin_tstz),
                                               pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_tstz,
                                                                                         i_dt_pend_req_tstz,
                                                                                         i_dt_begin_tstz))
                   ELSE
                    NULL
               END
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END get_col_request;

    FUNCTION get_col_transport
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_status_req_det IN exam_req_det.flg_status%TYPE,
        i_flg_status_mov     IN movement.flg_status%TYPE,
        i_flg_time_req       IN exam_req.flg_time%TYPE,
        i_flg_referral       IN exam_req_det.flg_referral%TYPE,
        i_flg_status_r       IN result_status.value%TYPE,
        i_dt_req_mov_tstz    IN movement.dt_req_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_shortcut(i_shortcut_name IN VARCHAR2) IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = i_shortcut_name
               AND id_software = i_prof.software
               AND id_institution IN (i_prof.institution, 0)
             ORDER BY id_institution DESC;
    
        l_id_shortcut_transport sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_transport    VARCHAR2(50 CHAR) := 'GRID_TRANSPORT';
    
        l_ret VARCHAR2(100);
    
    BEGIN
    
        g_error                 := 'OPEN C_SHORTCUT';
        l_id_shortcut_transport := NULL;
        OPEN c_shortcut(l_shortcut_transport);
        FETCH c_shortcut
            INTO l_id_shortcut_transport;
        CLOSE c_shortcut;
        l_id_shortcut_transport := nvl(l_id_shortcut_transport, '0');
    
        SELECT CASE
                   WHEN i_flg_status_mov = pk_alert_constant.g_mov_status_transp THEN
                    l_id_shortcut_transport ||
                    pk_utils.get_status_string(i_lang,
                                               i_prof,
                                               pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_mov_tstz,
                                                                                         i_dt_req_mov_tstz,
                                                                                         i_dt_req_mov_tstz),
                                               pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_mov_tstz,
                                                                                         i_dt_req_mov_tstz,
                                                                                         i_dt_req_mov_tstz),
                                               pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                          i_prof,
                                                                                          i_id_episode,
                                                                                          i_flg_time_req,
                                                                                          i_flg_status_req_det,
                                                                                          i_flg_referral,
                                                                                          i_flg_status_r,
                                                                                          i_dt_req_mov_tstz,
                                                                                          i_dt_req_mov_tstz,
                                                                                          i_dt_req_mov_tstz),
                                               pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_mov_tstz,
                                                                                         i_dt_req_mov_tstz,
                                                                                         i_dt_req_mov_tstz))
                   ELSE
                    NULL
               END
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END get_col_transport;

    FUNCTION get_col_execute
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_status_req_det IN exam_req_det.flg_status%TYPE,
        i_flg_status_mov     IN movement.flg_status%TYPE,
        i_flg_time_req       IN exam_req.flg_time%TYPE,
        i_flg_referral       IN exam_req_det.flg_referral%TYPE,
        i_flg_status_r       IN result_status.value%TYPE,
        i_dt_end_mov_tstz    IN movement.dt_end_tstz%TYPE,
        i_dt_req_tstz        IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz   IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin_tstz      IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_shortcut(i_shortcut_name IN VARCHAR2) IS
        
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = i_shortcut_name
               AND id_software = i_prof.software
               AND id_institution IN (i_prof.institution, 0)
             ORDER BY id_institution DESC;
    
        l_shortcut_image    VARCHAR2(50 CHAR) := 'GRID_IMAGE';
        l_id_shortcut_image sys_shortcut.id_sys_shortcut%TYPE;
    
        l_ret VARCHAR2(100);
    
    BEGIN
    
        l_id_shortcut_image := NULL;
        OPEN c_shortcut(l_shortcut_image);
        FETCH c_shortcut
            INTO l_id_shortcut_image;
        CLOSE c_shortcut;
        l_id_shortcut_image := nvl(l_id_shortcut_image, '0');
    
        SELECT CASE
                   WHEN i_flg_status_req_det = pk_exam_constant.g_exam_toexec THEN
                    l_id_shortcut_image ||
                    pk_utils.get_status_string(i_lang,
                                               i_prof,
                                               pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         pk_exam_constant.g_exam_req,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz),
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz),
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz)),
                                               pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         pk_exam_constant.g_exam_req,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz),
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz),
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz)),
                                               pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                          i_prof,
                                                                                          i_id_episode,
                                                                                          i_flg_time_req,
                                                                                          pk_exam_constant.g_exam_req,
                                                                                          i_flg_referral,
                                                                                          i_flg_status_r,
                                                                                          greatest(nvl(i_dt_end_mov_tstz,
                                                                                                       i_dt_req_tstz),
                                                                                                   i_dt_req_tstz),
                                                                                          greatest(nvl(i_dt_end_mov_tstz,
                                                                                                       i_dt_req_tstz),
                                                                                                   i_dt_req_tstz),
                                                                                          greatest(nvl(i_dt_end_mov_tstz,
                                                                                                       i_dt_req_tstz),
                                                                                                   i_dt_req_tstz)),
                                               pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         pk_exam_constant.g_exam_req,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz),
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz),
                                                                                         greatest(nvl(i_dt_end_mov_tstz,
                                                                                                      i_dt_req_tstz),
                                                                                                  i_dt_req_tstz)))
               
                   WHEN i_flg_status_req_det = pk_exam_constant.g_exam_exec THEN
                    l_id_shortcut_image ||
                    pk_utils.get_status_string(i_lang,
                                               i_prof,
                                               pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_tstz,
                                                                                         i_dt_pend_req_tstz,
                                                                                         i_dt_begin_tstz),
                                               pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_tstz,
                                                                                         i_dt_pend_req_tstz,
                                                                                         i_dt_begin_tstz),
                                               pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                          i_prof,
                                                                                          i_id_episode,
                                                                                          i_flg_time_req,
                                                                                          i_flg_status_req_det,
                                                                                          i_flg_referral,
                                                                                          i_flg_status_r,
                                                                                          i_dt_req_tstz,
                                                                                          i_dt_pend_req_tstz,
                                                                                          i_dt_begin_tstz),
                                               pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                         i_prof,
                                                                                         i_id_episode,
                                                                                         i_flg_time_req,
                                                                                         i_flg_status_req_det,
                                                                                         i_flg_referral,
                                                                                         i_flg_status_r,
                                                                                         i_dt_req_tstz,
                                                                                         i_dt_pend_req_tstz,
                                                                                         i_dt_begin_tstz))
                   ELSE
                    NULL
               END
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN NULL;
    END get_col_execute;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_image_tech;
/
