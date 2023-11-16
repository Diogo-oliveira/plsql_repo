/*-- Last Change Revision: $Rev: 2027298 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tech AS

    FUNCTION set_lab_test_grid_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis_req_det(l_id_episode IN NUMBER) IS
            WITH cso_tf AS
             (SELECT *
                FROM TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(i_lang,
                                                                    i_prof,
                                                                    l_id_episode,
                                                                    NULL,
                                                                    NULL,
                                                                    NULL,
                                                                    i_analysis_req_det)))
            SELECT nvl(i_analysis_req, ar.id_analysis_req),
                   ard.id_analysis,
                   ard.id_sample_type,
                   ard.id_exam_cat,
                   ar.id_episode,
                   ard.flg_time_harvest,
                   ard.flg_status,
                   ard.flg_referral,
                   ar.dt_req_tstz,
                   ard.dt_target_tstz,
                   ard.dt_pend_req_tstz,
                   nvl(cso.id_prof_ordered_by, ar.id_prof_writes),
                   ard.id_room_req,
                   ah.id_harvest,
                   h.flg_status,
                   h.dt_harvest_tstz,
                   h.dt_lab_reception_tstz,
                   h.dt_mov_begin_tstz,
                   h.id_room_receive_tube,
                   m.dt_begin_tstz,
                   m.dt_end_tstz,
                   CASE
                        WHEN ard.flg_status = pk_lab_tests_constant.g_analysis_result THEN
                         CASE
                             WHEN ard.flg_urgency != pk_lab_tests_constant.g_analysis_normal
                                  OR ares.flg_urgent = pk_lab_tests_constant.g_yes THEN
                              rs.value || pk_lab_tests_constant.g_analysis_urgent
                             ELSE
                              rs.value
                         END
                        ELSE
                         rs.value
                    END flg_status_result,
                   ard.id_task_dependency,
                   ard.flg_req_origin_module,
                   pk_announced_arrival.get_ann_arrival_id(i_prof.institution,
                                                           ei.id_software,
                                                           ar.id_episode,
                                                           ei.flg_unknown,
                                                           aa.id_announced_arrival,
                                                           aa.flg_status) id_announced_arrival,
                   coalesce(h.dt_harvest_tstz,
                            h.dt_begin_harvest,
                            ard.dt_pend_req_tstz,
                            ard.dt_target_tstz,
                            ar.dt_req_tstz) dt_order
              FROM analysis_req ar
             INNER JOIN analysis_req_det ard
                ON ard.id_analysis_req = ar.id_analysis_req
              LEFT JOIN cso_tf cso
                ON (ard.id_co_sign_order = cso.id_co_sign_hist)
              LEFT OUTER JOIN analysis_harvest ah
                ON ah.id_analysis_req_det = ard.id_analysis_req_det
              LEFT OUTER JOIN harvest h
                ON h.id_harvest = ah.id_harvest
              LEFT OUTER JOIN movement m
                ON m.id_movement = ard.id_movement
              LEFT OUTER JOIN (SELECT ar.id_analysis_req_det,
                                      ar.id_result_status,
                                      CASE
                                           WHEN pk_utils.is_number(dbms_lob.substr(ar.desc_analysis_result, 3800)) =
                                                pk_lab_tests_constant.g_yes
                                                AND ar.analysis_result_value_2 IS NULL THEN
                                            CASE
                                                WHEN ar.analysis_result_value_1 < ar.ref_val_min THEN
                                                 pk_lab_tests_constant.g_yes
                                                WHEN ar.analysis_result_value_1 > ar.ref_val_max THEN
                                                 pk_lab_tests_constant.g_yes
                                                ELSE
                                                 pk_lab_tests_constant.g_no
                                            END
                                           ELSE
                                            CASE
                                                WHEN ar.id_abnormality IS NOT NULL
                                                     AND ar.id_abnormality != 7 THEN
                                                 pk_lab_tests_constant.g_yes
                                                ELSE
                                                 pk_lab_tests_constant.g_no
                                            END
                                       END flg_urgent
                                 FROM (SELECT ar.id_analysis_req_det,
                                              ar.id_result_status,
                                              arp.desc_analysis_result,
                                              arp.analysis_result_value_1,
                                              arp.analysis_result_value_2,
                                              arp.ref_val_min,
                                              arp.ref_val_max,
                                              arp.id_abnormality,
                                              row_number() over(PARTITION BY id_harvest, id_analysis_req_par ORDER BY dt_ins_result_tstz DESC) rn
                                         FROM analysis_result ar, analysis_result_par arp
                                        WHERE ar.id_episode_orig = l_id_episode
                                          AND ar.id_analysis_result = arp.id_analysis_result) ar
                                WHERE ar.rn = 1) ares
                ON ares.id_analysis_req_det = ard.id_analysis_req_det
              LEFT OUTER JOIN result_status rs
                ON rs.id_result_status = ares.id_result_status
              JOIN epis_info ei
                ON (ar.id_episode = ei.id_episode OR ar.id_episode_origin = ei.id_episode)
              LEFT OUTER JOIN announced_arrival aa
                ON ar.id_episode = aa.id_episode
             WHERE ard.id_analysis_req_det = i_analysis_req_det;
    
        CURSOR c_sample_recipient IS
            SELECT ah.id_sample_recipient
              FROM analysis_harvest ah
             WHERE ah.id_analysis_req_det = i_analysis_req_det
               AND ah.flg_status = pk_lab_tests_constant.g_active;
    
        CURSOR c_patient IS
            SELECT nvl(i_patient, p.id_patient) id_patient,
                   p.gender,
                   p.age pat_age,
                   --pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   cr.num_clin_record
              FROM analysis_req_det ard, analysis_req ar, patient p, clin_record cr
             WHERE ard.id_analysis_req_det = i_analysis_req_det
               AND ard.id_analysis_req = ar.id_analysis_req
               AND ar.id_patient = p.id_patient
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
            SELECT cs.id_clinical_service, d.id_dept, ei.id_dep_clin_serv, ei.dt_first_obs_tstz dt_first_obs_tstz
              FROM episode e, epis_info ei, clinical_service cs, dept d
             WHERE e.id_episode = i_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_dep_clin_serv IS NOT NULL
               AND cs.id_clinical_service = nvl(l_clinical_service, e.id_clinical_service)
               AND e.id_dept = d.id_dept
               AND d.id_institution = i_prof.institution
            UNION
            SELECT cs.id_clinical_service, d.id_dept, ei.id_dep_clin_serv, ei.dt_first_obs_tstz dt_first_obs_tstz
              FROM episode e, epis_info ei, clinical_service cs, dept d
             WHERE e.id_episode = i_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_dep_clin_serv IS NULL
               AND cs.id_clinical_service = decode(l_clinical_service, -1, e.id_cs_requested, l_clinical_service)
               AND e.id_dept_requested = d.id_dept
               AND d.id_institution = i_prof.institution
            UNION
            SELECT NULL id_clinical_service, d.id_dept, ei.id_dep_clin_serv, ei.dt_first_obs_tstz dt_first_obs_tstz
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
    
        l_flg_referral analysis_req_det.flg_referral%TYPE;
    
        l_flg_status_h       harvest.flg_status%TYPE;
        l_dt_harvest         harvest.dt_harvest_tstz%TYPE;
        l_dt_lab_reception_h harvest.dt_lab_reception_tstz%TYPE;
        l_dt_mov_begin_h     harvest.dt_mov_begin_tstz%TYPE;
        l_dt_begin_m         movement.dt_begin_tstz%TYPE;
        l_dt_end_m           movement.dt_end_tstz%TYPE;
    
        l_flg_status_r VARCHAR2(2 CHAR);
    
        l_grid_task_lab grid_task_lab%ROWTYPE;
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_analysis_req_det IS NULL
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'PK_LAB_TECH.SET_LAB_TEST_GRID_TASK / i_analysis_req_det is null';
            RAISE g_other_exception;
        END IF;
    
        IF i_episode IS NULL
        THEN
            SELECT ar.id_episode
              INTO l_id_episode
              FROM analysis_req ar
             INNER JOIN analysis_req_det ard
                ON ard.id_analysis_req = ar.id_analysis_req
             WHERE ard.id_analysis_req_det = i_analysis_req_det;
        ELSE
            l_id_episode := i_episode;
        END IF;
    
        l_grid_task_lab.id_analysis_req_det := i_analysis_req_det;
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_grid_task_lab.id_patient,
                 l_grid_task_lab.gender,
                 l_grid_task_lab.pat_age,
                 l_grid_task_lab.num_clin_record;
        CLOSE c_patient;
    
        g_error := 'OPEN C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_grid_task_lab.id_epis_type,
                 l_grid_task_lab.flg_status_epis,
                 l_grid_task_lab.id_clinical_service,
                 l_grid_task_lab.id_software;
        CLOSE c_episode;
    
        g_error := 'OPEN C_EPIS_INFO';
        OPEN c_epis_info(l_grid_task_lab.id_clinical_service);
        FETCH c_epis_info
            INTO l_grid_task_lab.id_clinical_service,
                 l_grid_task_lab.id_dept,
                 l_grid_task_lab.id_dep_clin_serv,
                 l_grid_task_lab.dt_first_obs_tstz;
        CLOSE c_epis_info;
    
        g_error := 'OPEN C_TRIAGE_COLOR';
        OPEN c_triage_color;
        FETCH c_triage_color
            INTO l_grid_task_lab.acuity,
                 l_grid_task_lab.rank_acuity,
                 l_grid_task_lab.triage_color_text,
                 l_grid_task_lab.id_triage_color;
        CLOSE c_triage_color;
    
        g_error := 'OPEN C_SAMPLE_RECIPIENT';
        OPEN c_sample_recipient;
        FETCH c_sample_recipient
            INTO l_grid_task_lab.id_sample_recipient;
        CLOSE c_sample_recipient;
    
        g_error := 'OPEN C_ANALYSIS_REQ_DET';
        OPEN c_analysis_req_det(l_id_episode);
        FETCH c_analysis_req_det
            INTO l_grid_task_lab.id_analysis_req,
                 l_grid_task_lab.id_analysis,
                 l_grid_task_lab.id_sample_type,
                 l_grid_task_lab.id_exam_cat,
                 l_grid_task_lab.id_episode,
                 l_grid_task_lab.flg_time_harvest,
                 l_grid_task_lab.flg_status_ard,
                 l_flg_referral,
                 l_grid_task_lab.dt_req_tstz,
                 l_grid_task_lab.dt_target_tstz,
                 l_grid_task_lab.dt_pend_req_tstz,
                 l_grid_task_lab.id_professional,
                 l_grid_task_lab.id_room_req,
                 l_grid_task_lab.id_harvest,
                 l_flg_status_h,
                 l_dt_harvest,
                 l_dt_lab_reception_h,
                 l_dt_mov_begin_h,
                 l_grid_task_lab.id_room_receive_tube,
                 l_dt_begin_m,
                 l_dt_end_m,
                 l_flg_status_r,
                 l_grid_task_lab.id_task_dependency,
                 l_grid_task_lab.flg_req_origin_module,
                 l_grid_task_lab.id_announced_arrival,
                 l_grid_task_lab.dt_order;
        g_found := c_analysis_req_det%FOUND;
        CLOSE c_analysis_req_det;
    
        IF NOT g_found
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'PK_LAB_TECH.SET_LAB_TEST_GRID_TASK / ' || g_error;
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN C_ANALYSIS_REQ_DET';
        IF l_grid_task_lab.flg_status_ard IN
           (pk_lab_tests_constant.g_analysis_req, pk_lab_tests_constant.g_analysis_pending)
        THEN
            l_grid_task_lab.request := '0' ||
                                       pk_utils.get_status_string(i_lang,
                                                                  i_prof,
                                                                  pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   l_grid_task_lab.id_episode,
                                                                                                                   l_grid_task_lab.flg_time_harvest,
                                                                                                                   l_grid_task_lab.flg_status_ard,
                                                                                                                   l_flg_referral,
                                                                                                                   l_flg_status_h,
                                                                                                                   l_flg_status_r,
                                                                                                                   NULL,
                                                                                                                   l_grid_task_lab.dt_req_tstz,
                                                                                                                   l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                   l_grid_task_lab.dt_target_tstz),
                                                                  pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   l_grid_task_lab.id_episode,
                                                                                                                   l_grid_task_lab.flg_time_harvest,
                                                                                                                   l_grid_task_lab.flg_status_ard,
                                                                                                                   l_flg_referral,
                                                                                                                   l_flg_status_h,
                                                                                                                   l_flg_status_r,
                                                                                                                   NULL,
                                                                                                                   l_grid_task_lab.dt_req_tstz,
                                                                                                                   l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                   l_grid_task_lab.dt_target_tstz),
                                                                  pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                    i_prof,
                                                                                                                    l_grid_task_lab.id_episode,
                                                                                                                    l_grid_task_lab.flg_time_harvest,
                                                                                                                    l_grid_task_lab.flg_status_ard,
                                                                                                                    l_flg_referral,
                                                                                                                    l_flg_status_h,
                                                                                                                    l_flg_status_r,
                                                                                                                    NULL,
                                                                                                                    l_grid_task_lab.dt_req_tstz,
                                                                                                                    l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                    l_grid_task_lab.dt_target_tstz),
                                                                  pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   l_grid_task_lab.id_episode,
                                                                                                                   l_grid_task_lab.flg_time_harvest,
                                                                                                                   l_grid_task_lab.flg_status_ard,
                                                                                                                   l_flg_referral,
                                                                                                                   l_flg_status_h,
                                                                                                                   l_flg_status_r,
                                                                                                                   NULL,
                                                                                                                   l_grid_task_lab.dt_req_tstz,
                                                                                                                   l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                   l_grid_task_lab.dt_target_tstz));
        END IF;
    
        IF l_grid_task_lab.flg_status_ard = pk_lab_tests_constant.g_analysis_toexec
        THEN
            IF l_flg_status_h = pk_lab_tests_constant.g_harvest_pending
            THEN
                l_grid_task_lab.harvest := '0' ||
                                           pk_utils.get_status_string(i_lang,
                                                                      i_prof,
                                                                      pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz),
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz),
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz)),
                                                                      pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz),
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz),
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz)),
                                                                      pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                        i_prof,
                                                                                                                        l_grid_task_lab.id_episode,
                                                                                                                        l_grid_task_lab.flg_time_harvest,
                                                                                                                        pk_lab_tests_constant.g_analysis_req,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        coalesce(l_dt_harvest,
                                                                                                                                 l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                 l_grid_task_lab.dt_target_tstz,
                                                                                                                                 l_grid_task_lab.dt_req_tstz),
                                                                                                                        coalesce(l_dt_harvest,
                                                                                                                                 l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                 l_grid_task_lab.dt_target_tstz,
                                                                                                                                 l_grid_task_lab.dt_req_tstz),
                                                                                                                        coalesce(l_dt_harvest,
                                                                                                                                 l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                 l_grid_task_lab.dt_target_tstz,
                                                                                                                                 l_grid_task_lab.dt_req_tstz)),
                                                                      pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz),
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz),
                                                                                                                       coalesce(l_dt_harvest,
                                                                                                                                l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                                l_grid_task_lab.dt_target_tstz,
                                                                                                                                l_grid_task_lab.dt_req_tstz)));
            
            ELSIF l_flg_status_h = pk_lab_tests_constant.g_harvest_collected
            THEN
                l_grid_task_lab.harvest := '0' ||
                                           pk_utils.get_status_string(i_lang,
                                                                      i_prof,
                                                                      pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       l_dt_harvest,
                                                                                                                       l_dt_harvest,
                                                                                                                       l_dt_harvest),
                                                                      pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       l_dt_harvest,
                                                                                                                       l_dt_harvest,
                                                                                                                       l_dt_harvest),
                                                                      pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                        i_prof,
                                                                                                                        l_grid_task_lab.id_episode,
                                                                                                                        l_grid_task_lab.flg_time_harvest,
                                                                                                                        pk_lab_tests_constant.g_analysis_req,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        l_dt_harvest,
                                                                                                                        l_dt_harvest,
                                                                                                                        l_dt_harvest),
                                                                      pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       l_dt_harvest,
                                                                                                                       l_dt_harvest,
                                                                                                                       l_dt_harvest));
            ELSIF l_flg_status_h = pk_lab_tests_constant.g_harvest_transp
            THEN
                l_grid_task_lab.transport := '0' ||
                                             pk_utils.get_status_string(i_lang,
                                                                        i_prof,
                                                                        pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                         i_prof,
                                                                                                                         l_grid_task_lab.id_episode,
                                                                                                                         l_grid_task_lab.flg_time_harvest,
                                                                                                                         pk_lab_tests_constant.g_analysis_req,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest),
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest),
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest)),
                                                                        pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                         i_prof,
                                                                                                                         l_grid_task_lab.id_episode,
                                                                                                                         l_grid_task_lab.flg_time_harvest,
                                                                                                                         pk_lab_tests_constant.g_analysis_req,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest),
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest),
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest)),
                                                                        pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                          i_prof,
                                                                                                                          l_grid_task_lab.id_episode,
                                                                                                                          l_grid_task_lab.flg_time_harvest,
                                                                                                                          pk_lab_tests_constant.g_analysis_req,
                                                                                                                          NULL,
                                                                                                                          NULL,
                                                                                                                          NULL,
                                                                                                                          NULL,
                                                                                                                          coalesce(l_dt_begin_m,
                                                                                                                                   l_dt_mov_begin_h,
                                                                                                                                   l_dt_harvest),
                                                                                                                          coalesce(l_dt_begin_m,
                                                                                                                                   l_dt_mov_begin_h,
                                                                                                                                   l_dt_harvest),
                                                                                                                          coalesce(l_dt_begin_m,
                                                                                                                                   l_dt_mov_begin_h,
                                                                                                                                   l_dt_harvest)),
                                                                        pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                         i_prof,
                                                                                                                         l_grid_task_lab.id_episode,
                                                                                                                         l_grid_task_lab.flg_time_harvest,
                                                                                                                         pk_lab_tests_constant.g_analysis_req,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         NULL,
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest),
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest),
                                                                                                                         coalesce(l_dt_begin_m,
                                                                                                                                  l_dt_mov_begin_h,
                                                                                                                                  l_dt_harvest)));
            
            ELSIF l_flg_status_h = pk_lab_tests_constant.g_harvest_finished
            THEN
                l_grid_task_lab.execute := '0' ||
                                           pk_utils.get_status_string(i_lang,
                                                                      i_prof,
                                                                      pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest),
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest),
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest)),
                                                                      pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest),
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest),
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest)),
                                                                      pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                        i_prof,
                                                                                                                        l_grid_task_lab.id_episode,
                                                                                                                        l_grid_task_lab.flg_time_harvest,
                                                                                                                        pk_lab_tests_constant.g_analysis_req,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        NULL,
                                                                                                                        coalesce(l_dt_end_m,
                                                                                                                                 l_dt_lab_reception_h,
                                                                                                                                 l_dt_harvest),
                                                                                                                        coalesce(l_dt_end_m,
                                                                                                                                 l_dt_lab_reception_h,
                                                                                                                                 l_dt_harvest),
                                                                                                                        coalesce(l_dt_end_m,
                                                                                                                                 l_dt_lab_reception_h,
                                                                                                                                 l_dt_harvest)),
                                                                      pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                       i_prof,
                                                                                                                       l_grid_task_lab.id_episode,
                                                                                                                       l_grid_task_lab.flg_time_harvest,
                                                                                                                       pk_lab_tests_constant.g_analysis_req,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       NULL,
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest),
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest),
                                                                                                                       coalesce(l_dt_end_m,
                                                                                                                                l_dt_lab_reception_h,
                                                                                                                                l_dt_harvest)));
            END IF;
        END IF;
    
        IF l_grid_task_lab.flg_status_ard = pk_lab_tests_constant.g_analysis_result
        THEN
            l_grid_task_lab.complete := '0' ||
                                        pk_utils.get_status_string(i_lang,
                                                                   i_prof,
                                                                   pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                    i_prof,
                                                                                                                    l_grid_task_lab.id_episode,
                                                                                                                    l_grid_task_lab.flg_time_harvest,
                                                                                                                    l_grid_task_lab.flg_status_ard,
                                                                                                                    l_flg_referral,
                                                                                                                    l_flg_status_h,
                                                                                                                    l_flg_status_r,
                                                                                                                    NULL,
                                                                                                                    l_grid_task_lab.dt_req_tstz,
                                                                                                                    l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                    l_grid_task_lab.dt_target_tstz),
                                                                   pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                    i_prof,
                                                                                                                    l_grid_task_lab.id_episode,
                                                                                                                    l_grid_task_lab.flg_time_harvest,
                                                                                                                    l_grid_task_lab.flg_status_ard,
                                                                                                                    l_flg_referral,
                                                                                                                    l_flg_status_h,
                                                                                                                    l_flg_status_r,
                                                                                                                    NULL,
                                                                                                                    l_grid_task_lab.dt_req_tstz,
                                                                                                                    l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                    l_grid_task_lab.dt_target_tstz),
                                                                   pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                     i_prof,
                                                                                                                     l_grid_task_lab.id_episode,
                                                                                                                     l_grid_task_lab.flg_time_harvest,
                                                                                                                     l_grid_task_lab.flg_status_ard,
                                                                                                                     l_flg_referral,
                                                                                                                     l_flg_status_h,
                                                                                                                     l_flg_status_r,
                                                                                                                     NULL,
                                                                                                                     l_grid_task_lab.dt_req_tstz,
                                                                                                                     l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                     l_grid_task_lab.dt_target_tstz),
                                                                   pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                    i_prof,
                                                                                                                    l_grid_task_lab.id_episode,
                                                                                                                    l_grid_task_lab.flg_time_harvest,
                                                                                                                    l_grid_task_lab.flg_status_ard,
                                                                                                                    l_flg_referral,
                                                                                                                    l_flg_status_h,
                                                                                                                    l_flg_status_r,
                                                                                                                    NULL,
                                                                                                                    l_grid_task_lab.dt_req_tstz,
                                                                                                                    l_grid_task_lab.dt_pend_req_tstz,
                                                                                                                    l_grid_task_lab.dt_target_tstz));
        END IF;
    
        g_error := 'MERGE INTO GRID_TASK_LAB';
        MERGE INTO grid_task_lab gtl
        USING (SELECT l_grid_task_lab.id_patient id_patient,
                      l_grid_task_lab.id_harvest id_harvest,
                      l_grid_task_lab.id_episode id_episode,
                      decode(l_grid_task_lab.id_episode, NULL, NULL, l_grid_task_lab.id_epis_type) id_epis_type,
                      decode(l_grid_task_lab.id_episode, NULL, NULL, l_grid_task_lab.flg_status_epis) flg_status_epis,
                      nvl(l_grid_task_lab.id_software, i_prof.software) id_software,
                      l_grid_task_lab.dt_first_obs_tstz dt_first_obs_tstz,
                      l_grid_task_lab.id_sample_recipient id_sample_recipient,
                      l_grid_task_lab.flg_status_ard flg_status_ard,
                      l_grid_task_lab.dt_target_tstz dt_target_tstz,
                      l_grid_task_lab.flg_time_harvest flg_time_harvest,
                      l_grid_task_lab.dt_pend_req_tstz dt_pend_req_tstz,
                      l_grid_task_lab.acuity acuity,
                      l_grid_task_lab.rank_acuity rank_acuity,
                      l_grid_task_lab.triage_color_text triage_color_text,
                      l_grid_task_lab.id_triage_color id_triage_color,
                      l_grid_task_lab.request request,
                      l_grid_task_lab.harvest harvest,
                      l_grid_task_lab.transport transport,
                      l_grid_task_lab.execute EXECUTE,
                      l_grid_task_lab.complete complete,
                      l_grid_task_lab.dt_order dt_order,
                      l_grid_task_lab.id_analysis_req id_analysis_req,
                      l_grid_task_lab.id_analysis_req_det id_analysis_req_det,
                      l_grid_task_lab.id_analysis id_analysis,
                      l_grid_task_lab.id_sample_type id_sample_type,
                      l_grid_task_lab.id_exam_cat id_exam_cat,
                      nvl(l_grid_task_lab.id_institution, i_prof.institution) id_institution,
                      l_grid_task_lab.gender gender,
                      l_grid_task_lab.pat_age pat_age,
                      l_grid_task_lab.num_clin_record num_clin_record,
                      l_grid_task_lab.id_dept id_dept,
                      l_grid_task_lab.id_clinical_service id_clinical_service,
                      l_grid_task_lab.id_dep_clin_serv id_dep_clin_serv,
                      l_grid_task_lab.id_professional id_professional,
                      l_grid_task_lab.dt_req_tstz dt_req_tstz,
                      l_grid_task_lab.id_room_req id_room_req,
                      l_grid_task_lab.id_room_receive_tube id_room_receive_tube,
                      l_grid_task_lab.id_task_dependency id_task_dependency,
                      l_grid_task_lab.flg_req_origin_module flg_req_origin_module,
                      l_grid_task_lab.id_announced_arrival id_announced_arrival
                 FROM dual) t
        ON (gtl.id_analysis_req = t.id_analysis_req AND gtl.id_analysis_req_det = t.id_analysis_req_det)
        WHEN MATCHED THEN
            UPDATE
               SET id_patient            = t.id_patient,
                   id_harvest            = t.id_harvest,
                   id_episode            = t.id_episode,
                   id_epis_type          = t.id_epis_type,
                   flg_status_epis       = t.flg_status_epis,
                   id_software           = t.id_software,
                   dt_first_obs_tstz     = t.dt_first_obs_tstz,
                   id_sample_recipient   = t.id_sample_recipient,
                   flg_status_ard        = t.flg_status_ard,
                   dt_target_tstz        = t.dt_target_tstz,
                   flg_time_harvest      = t.flg_time_harvest,
                   dt_pend_req_tstz      = t.dt_pend_req_tstz,
                   acuity                = t.acuity,
                   rank_acuity           = t.rank_acuity,
                   triage_color_text     = t.triage_color_text,
                   id_triage_color       = t.id_triage_color,
                   request               = t.request,
                   harvest               = t.harvest,
                   transport             = t.transport,
                   EXECUTE               = t.execute,
                   complete              = t.complete,
                   dt_order              = t.dt_order,
                   id_analysis           = t.id_analysis,
                   id_sample_type        = t.id_sample_type,
                   id_exam_cat           = t.id_exam_cat,
                   id_institution        = t.id_institution,
                   gender                = t.gender,
                   pat_age               = t.pat_age,
                   num_clin_record       = t.num_clin_record,
                   id_dept               = nvl(t.id_dept, gtl.id_dept),
                   id_clinical_service   = t.id_clinical_service,
                   id_dep_clin_serv      = t.id_dep_clin_serv,
                   id_professional       = t.id_professional,
                   dt_req_tstz           = t.dt_req_tstz,
                   id_room_req           = t.id_room_req,
                   id_room_receive_tube  = t.id_room_receive_tube,
                   id_task_dependency    = t.id_task_dependency,
                   flg_req_origin_module = t.flg_req_origin_module,
                   id_announced_arrival  = t.id_announced_arrival
        WHEN NOT MATCHED THEN
            INSERT
                (id_patient,
                 id_harvest,
                 id_episode,
                 id_epis_type,
                 flg_status_epis,
                 id_software,
                 dt_first_obs_tstz,
                 id_sample_recipient,
                 flg_status_ard,
                 dt_target_tstz,
                 flg_time_harvest,
                 dt_pend_req_tstz,
                 acuity,
                 rank_acuity,
                 triage_color_text,
                 id_triage_color,
                 request,
                 harvest,
                 transport,
                 EXECUTE,
                 complete,
                 dt_order,
                 id_analysis_req,
                 id_analysis_req_det,
                 id_analysis,
                 id_sample_type,
                 id_exam_cat,
                 id_institution,
                 gender,
                 pat_age,
                 num_clin_record,
                 id_dept,
                 id_clinical_service,
                 id_dep_clin_serv,
                 id_professional,
                 dt_req_tstz,
                 id_room_req,
                 id_room_receive_tube,
                 id_task_dependency,
                 flg_req_origin_module,
                 id_announced_arrival)
            VALUES
                (t.id_patient,
                 t.id_harvest,
                 t.id_episode,
                 t.id_epis_type,
                 t.flg_status_epis,
                 t.id_software,
                 t.dt_first_obs_tstz,
                 t.id_sample_recipient,
                 t.flg_status_ard,
                 t.dt_target_tstz,
                 t.flg_time_harvest,
                 t.dt_pend_req_tstz,
                 t.acuity,
                 t.rank_acuity,
                 t.triage_color_text,
                 t.id_triage_color,
                 t.request,
                 t.harvest,
                 t.transport,
                 t.execute,
                 t.complete,
                 t.dt_order,
                 t.id_analysis_req,
                 t.id_analysis_req_det,
                 t.id_analysis,
                 t.id_sample_type,
                 t.id_exam_cat,
                 t.id_institution,
                 t.gender,
                 t.pat_age,
                 t.num_clin_record,
                 t.id_dept,
                 t.id_clinical_service,
                 t.id_dep_clin_serv,
                 t.id_professional,
                 t.dt_req_tstz,
                 t.id_room_req,
                 t.id_room_receive_tube,
                 t.id_task_dependency,
                 t.flg_req_origin_module,
                 t.id_announced_arrival) WHERE
                (l_grid_task_lab.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e AND
                 l_grid_task_lab.flg_status_ard NOT IN
                 (pk_lab_tests_constant.g_analysis_cancel,
                  pk_lab_tests_constant.g_analysis_read,
                  pk_lab_tests_constant.g_analysis_review) AND l_grid_task_lab.dt_target_tstz IS NOT NULL AND
                 nvl(l_grid_task_lab.id_room_req, l_grid_task_lab.id_room_receive_tube) IS NOT NULL) OR
                (l_grid_task_lab.flg_time_harvest IN
                 (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d) AND
                 l_grid_task_lab.flg_status_ard NOT IN
                 (pk_lab_tests_constant.g_analysis_cancel,
                  pk_lab_tests_constant.g_analysis_read,
                  pk_lab_tests_constant.g_analysis_review)) OR
                (l_grid_task_lab.flg_status_ard IN
                 (pk_lab_tests_constant.g_analysis_req, pk_lab_tests_constant.g_analysis_toexec) AND
                 l_grid_task_lab.flg_status_epis = pk_alert_constant.g_epis_status_inactive) OR
                (l_grid_task_lab.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND
                 l_grid_task_lab.flg_status_ard NOT IN
                 (pk_lab_tests_constant.g_analysis_cancel,
                  pk_lab_tests_constant.g_analysis_read,
                  pk_lab_tests_constant.g_analysis_review) AND l_grid_task_lab.dt_target_tstz IS NOT NULL AND
                 nvl(l_grid_task_lab.id_room_req, l_grid_task_lab.id_room_receive_tube) IS NOT NULL AND
                 l_grid_task_lab.id_episode IS NOT NULL);
    
        DELETE grid_task_lab gtl
         WHERE gtl.id_analysis_req_det = i_analysis_req_det
           AND l_grid_task_lab.id_epis_type != pk_lab_tests_constant.g_episode_type_lab
           AND (gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_predefined,
                                       pk_lab_tests_constant.g_analysis_draft,
                                       pk_lab_tests_constant.g_analysis_sos,
                                       pk_lab_tests_constant.g_analysis_read,
                                       pk_lab_tests_constant.g_analysis_cancel) OR
               (l_grid_task_lab.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND gtl.id_episode IS NULL) OR
               (gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_result AND
               gtl.id_software = pk_alert_constant.g_soft_outpatient) OR
               (gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_result AND
               gtl.flg_status_epis = pk_alert_constant.g_epis_status_pendent) OR
               (l_flg_referral IN (pk_lab_tests_constant.g_flg_referral_r,
                                    pk_lab_tests_constant.g_flg_referral_s,
                                    pk_lab_tests_constant.g_flg_referral_i)));
    
        IF l_grid_task_lab.id_epis_type != pk_lab_tests_constant.g_episode_type_lab
           AND l_grid_task_lab.flg_status_epis = pk_alert_constant.g_epis_status_inactive
        THEN
            DELETE grid_task_lab gtl
             WHERE gtl.id_episode = l_grid_task_lab.id_episode;
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
                                              'SET_LAB_TEST_GRID_TASK',
                                              o_error);
            RETURN FALSE;
    END set_lab_test_grid_task;

    PROCEDURE set_lab_test_episode_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_id_analysis_req     analysis_req.id_analysis_req%TYPE;
        l_id_analysis_req_det analysis_req_det.id_analysis_req_det%TYPE;
        l_flg_status          episode.flg_status%TYPE;
    
        CURSOR c_grid_task IS
            SELECT /*+ opt_estimate(table e rows=1) */
             gtl.id_analysis_req, gtl.id_analysis_req_det, e.flg_status
              FROM grid_task_lab gtl
              JOIN episode e
                ON e.id_episode = gtl.id_episode
             WHERE e.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                column_value
                                 FROM TABLE(i_rowids) t);
    
    BEGIN
    
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'EPISODE',
                                                 i_expected_dg_table_name => 'GRID_TASK_LAB',
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
                        INTO l_id_analysis_req, l_id_analysis_req_det, l_flg_status;
                    EXIT WHEN c_grid_task%NOTFOUND;
                
                    UPDATE grid_task_lab gtl
                       SET gtl.flg_status_epis = l_flg_status
                     WHERE gtl.id_analysis_req = l_id_analysis_req
                       AND gtl.id_analysis_req_det = l_id_analysis_req_det;
                END LOOP;
                CLOSE c_grid_task;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_lab_test_episode_status;

    FUNCTION get_technician_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_collect_pending sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('HARVEST_PENDING_REQ', i_prof);
        l_num_days_back   sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK',
                                                                           i_prof);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
    
        DELETE grid_task_lab gtl
         WHERE gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_result
           AND gtl.dt_req_tstz <= l_dt_begin - INTERVAL '1'
         DAY
           AND gtl.id_epis_type != pk_lab_tests_constant.g_episode_type_lab;
    
        DELETE grid_task_lab gtl
         WHERE gtl.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtl.id_epis_type != pk_lab_tests_constant.g_episode_type_lab;
    
        l_num_days_back := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        DELETE grid_task_lab gtl
         WHERE gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_result,
                                      pk_lab_tests_constant.g_analysis_read,
                                      pk_lab_tests_constant.g_analysis_cancel)
           AND gtl.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
           AND gtl.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtl.id_epis_type = pk_lab_tests_constant.g_episode_type_lab;
    
        COMMIT;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT DISTINCT gtl.id_patient,
                            gtl.id_harvest,
                            0 id_analysis_req,
                            gtl.id_episode,
                            gtl.id_epis_type,
                            gtl.acuity,
                            gtl.rank_acuity,
                            gtl.triage_color_text color_text,
                            (SELECT pk_edis_triage.get_epis_esi_level(i_lang,
                                                                      i_prof,
                                                                      gtl.id_episode,
                                                                      gtl.id_triage_color)
                               FROM dual) esi_level,
                            (SELECT pk_date_utils.date_send_tsz(i_lang, gtl.dt_first_obs_tstz, i_prof)
                               FROM dual) dt_first_obs,
                            (SELECT pk_translation.get_translation(i_lang,
                                                                   'AB_SOFTWARE.CODE_SOFTWARE.' || gtl.id_software)
                               FROM dual) epis_type,
                            (SELECT pk_translation.get_translation(i_lang,
                                                                   'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                   gtl.id_institution)
                               FROM dual) desc_institution,
                            (SELECT pk_patient.get_pat_name(i_lang, i_prof, gtl.id_patient, gtl.id_episode, NULL)
                               FROM dual) desc_patient,
                            (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, gtl.id_patient)
                               FROM dual) pat_ndo,
                            (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, gtl.id_patient)
                               FROM dual) pat_nd_icon,
                            (SELECT pk_translation.get_translation(i_lang,
                                                                   'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                   gtl.id_sample_recipient)
                               FROM dual) desc_analysis,
                            gtl.request col_request,
                            gtl.harvest col_harvest,
                            gtl.transport col_transport,
                            gtl.execute col_execute,
                            gtl.complete col_complete,
                            (SELECT pk_patient.get_pat_name_to_sort(i_lang, i_prof, gtl.id_patient, gtl.id_episode, NULL)
                               FROM dual) order_name,
                            decode(gtl.flg_status_ard,
                                   pk_lab_tests_constant.g_analysis_req,
                                   row_number()
                                   over(ORDER BY gtl.id_episode,
                                        (SELECT pk_sysdomain.get_domain(i_lang,
                                                                        i_prof,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        gtl.flg_status_ard,
                                                                        NULL)
                                           FROM dual),
                                        coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)),
                                   pk_lab_tests_constant.g_analysis_pending,
                                   row_number()
                                   over(ORDER BY gtl.id_episode,
                                        (SELECT pk_sysdomain.get_domain(i_lang,
                                                                        i_prof,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        gtl.flg_status_ard,
                                                                        NULL)
                                           FROM dual),
                                        coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)),
                                   row_number()
                                   over(ORDER BY gtl.id_episode,
                                        (SELECT pk_sysdomain.get_domain(i_lang,
                                                                        i_prof,
                                                                        'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                        gtl.flg_status_ard,
                                                                        NULL)
                                           FROM dual),
                                        coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz) DESC)) rank,
                            (SELECT pk_date_utils.date_send_tsz(i_lang, gtl.dt_order, i_prof)
                               FROM dual) dt_ord,
                            g_sysdate_char dt_server
              FROM (SELECT DISTINCT gtl.id_patient,
                                    gtl.id_harvest,
                                    gtl.id_episode,
                                    gtl.id_epis_type,
                                    gtl.acuity,
                                    gtl.rank_acuity,
                                    gtl.triage_color_text,
                                    gtl.id_triage_color,
                                    gtl.dt_first_obs_tstz,
                                    gtl.id_software,
                                    gtl.id_institution,
                                    gtl.id_sample_recipient,
                                    gtl.request,
                                    gtl.harvest,
                                    gtl.transport,
                                    gtl.execute,
                                    gtl.complete,
                                    gtl.id_announced_arrival,
                                    gtl.flg_status_ard,
                                    gtl.dt_pend_req_tstz,
                                    gtl.dt_target_tstz,
                                    gtl.dt_req_tstz,
                                    gtl.dt_order
                      FROM grid_task_lab gtl
                     WHERE (EXISTS
                            (SELECT 1
                               FROM institution i
                              WHERE i.id_parent = (SELECT i.id_parent
                                                     FROM institution i
                                                    WHERE i.id_institution = i_prof.institution)
                                AND i.id_institution = gtl.id_institution) OR gtl.id_institution = i_prof.institution)
                       AND ((gtl.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e AND
                           gtl.flg_status_epis = pk_alert_constant.g_epis_status_active AND
                           ((gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_req,
                                                      pk_lab_tests_constant.g_analysis_oncollection,
                                                      pk_lab_tests_constant.g_analysis_toexec,
                                                      pk_lab_tests_constant.g_analysis_result)) OR
                           (gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_req,
                                                      pk_lab_tests_constant.g_analysis_pending,
                                                      pk_lab_tests_constant.g_analysis_oncollection,
                                                      pk_lab_tests_constant.g_analysis_toexec,
                                                      pk_lab_tests_constant.g_analysis_result) AND
                           nvl(l_collect_pending, pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_yes))) OR
                           (gtl.flg_time_harvest IN
                           (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d) AND
                           gtl.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end AND
                           gtl.flg_status_ard NOT IN
                           (pk_lab_tests_constant.g_analysis_tosched, pk_lab_tests_constant.g_analysis_sched)) OR
                           (gtl.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND
                           gtl.flg_status_epis = pk_alert_constant.g_epis_status_active AND
                           ((gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_req,
                                                      pk_lab_tests_constant.g_analysis_oncollection,
                                                      pk_lab_tests_constant.g_analysis_toexec,
                                                      pk_lab_tests_constant.g_analysis_result)) OR
                           (gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_req,
                                                      pk_lab_tests_constant.g_analysis_pending,
                                                      pk_lab_tests_constant.g_analysis_oncollection,
                                                      pk_lab_tests_constant.g_analysis_toexec,
                                                      pk_lab_tests_constant.g_analysis_result) AND
                           nvl(l_collect_pending, pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_yes))))
                       AND EXISTS
                     (SELECT 1
                              FROM prof_room pr
                             WHERE pr.id_professional = i_prof.id
                               AND pr.id_room = nvl(gtl.id_room_receive_tube, gtl.id_room_req))
                          -- End fix
                          -- Dept with data, clinical_service with data, dep_clin_serv with data
                       AND ((EXISTS (SELECT 1
                                       FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                                      WHERE pdcs.id_professional = i_prof.id
                                        AND pdcs.id_institution = gtl.id_institution
                                        AND pdcs.flg_status = pk_lab_tests_constant.g_selected
                                        AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                        AND dcs.id_department = d.id_department
                                        AND dcs.id_dep_clin_serv = gtl.id_dep_clin_serv
                                        AND dcs.id_clinical_service = gtl.id_clinical_service
                                        AND d.id_dept = gtl.id_dept)) OR
                           -- Dept with data, clinical_service with data, dep_clin_serv is NULL
                           (gtl.id_dep_clin_serv IS NULL AND EXISTS
                            (SELECT 1
                                FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                               WHERE pdcs.id_professional = i_prof.id
                                 AND pdcs.id_institution = gtl.id_institution
                                 AND pdcs.flg_status = pk_lab_tests_constant.g_selected
                                 AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                 AND dcs.id_clinical_service = gtl.id_clinical_service
                                 AND dcs.id_department = d.id_department
                                 AND d.id_dept = gtl.id_dept)) OR
                           -- Dept with data, clinical_service IS NULL, dep_clin_serv is NULL
                           (gtl.id_dep_clin_serv IS NULL AND gtl.id_clinical_service IS NULL AND EXISTS
                            (SELECT 1
                                FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                               WHERE pdcs.id_professional = i_prof.id
                                 AND pdcs.id_institution = gtl.id_institution
                                 AND pdcs.flg_status = pk_lab_tests_constant.g_selected
                                 AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                 AND dcs.id_department = d.id_department
                                 AND d.id_dept = gtl.id_dept)) OR
                           -- Dept is NULL, clinical_service with data, dep_clin_serv with data
                           (gtl.id_dept IS NULL AND EXISTS
                            (SELECT 1
                                FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                               WHERE pdcs.id_professional = i_prof.id
                                 AND pdcs.id_institution = gtl.id_institution
                                 AND pdcs.flg_status = pk_lab_tests_constant.g_selected
                                 AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                 AND dcs.id_dep_clin_serv = gtl.id_dep_clin_serv
                                 AND dcs.id_clinical_service = gtl.id_clinical_service)) OR
                           -- Dept is NULL, clinical_service is NULL, dep_clin_serv with data
                           (gtl.id_dept IS NULL AND gtl.id_clinical_service IS NULL AND EXISTS
                            (SELECT 1
                                FROM prof_dep_clin_serv pdcs
                               WHERE pdcs.id_professional = i_prof.id
                                 AND pdcs.id_institution = gtl.id_institution
                                 AND pdcs.flg_status = pk_lab_tests_constant.g_selected
                                 AND pdcs.id_dep_clin_serv = gtl.id_dep_clin_serv)) OR
                           -- Dept is NULL, clinical_service is NULL, dep_clin_serv is NULL
                           (gtl.id_dep_clin_serv IS NULL AND gtl.id_clinical_service IS NULL AND gtl.id_dept IS NULL) OR
                           -- Dept with data, clinical_service is -1, dep_clin_serv is NULL (LAB episodes)
                           (gtl.id_dep_clin_serv IS NULL AND gtl.id_clinical_service = -1 AND EXISTS
                            (SELECT 1
                                FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                               WHERE pdcs.id_professional = i_prof.id
                                 AND pdcs.id_institution = gtl.id_institution
                                 AND pdcs.flg_status = pk_lab_tests_constant.g_selected
                                 AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                                 AND dcs.id_department = d.id_department
                                 AND d.id_dept = gtl.id_dept)))
                       AND gtl.id_announced_arrival IS NOT NULL
                    UNION ALL
                    SELECT DISTINCT s.id_patient,
                                    gtl.id_harvest,
                                    ei.id_episode,
                                    pk_alert_constant.g_epis_type_lab id_epis_type,
                                    NULL                              acuity,
                                    NULL                              rank_acuity,
                                    NULL                              triage_color_text,
                                    NULL                              id_triage_color,
                                    NULL                              dt_first_obs_tstz,
                                    pk_alert_constant.g_soft_labtech  id_software,
                                    s.id_inst_requests                id_institution,
                                    gtl.id_sample_recipient,
                                    gtl.request                       col_request,
                                    gtl.harvest                       col_harvest,
                                    gtl.transport                     col_transport,
                                    gtl.execute                       col_execute,
                                    gtl.complete                      col_complete,
                                    NULL                              id_announced_arrival,
                                    NULL                              flg_status_ard,
                                    NULL                              dt_pend_req_tstz,
                                    s.dt_begin                        dt_target_tstz,
                                    NULL                              dt_req_tstz,
                                    NULL                              dt_order
                      FROM grid_task_lab gtl,
                           TABLE(pk_schedule_lab.get_today_lab_appoints(i_lang, i_prof)) s,
                           epis_info ei
                     WHERE s.id_analysis_req IS NULL
                       AND s.id_schedule = ei.id_schedule
                       AND ei.id_episode = gtl.id_episode(+)) gtl
             ORDER BY rank_acuity, rank, dt_ord;
    
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

    FUNCTION get_patient_by_harvest_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_barcode IN harvest.barcode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis IS
            SELECT 'X'
              FROM harvest h, analysis_harvest ah, lab_tests_ea lte, episode e
             WHERE h.barcode = i_barcode
               AND h.id_harvest = ah.id_harvest
               AND ah.id_analysis_req_det = lte.id_analysis_req_det
               AND lte.id_institution = i_prof.institution
               AND (lte.id_episode = e.id_episode OR lte.id_prev_episode = e.id_episode)
               AND e.id_visit = h.id_visit;
    
        l_char VARCHAR2(1);
    
    BEGIN
    
        g_error := 'OPEN C_ANALYSIS';
        OPEN c_analysis;
        FETCH c_analysis
            INTO l_char;
        g_found := c_analysis%FOUND;
        CLOSE c_analysis;
    
        IF NOT g_found
        THEN
            pk_types.open_my_cursor(o_list);
        ELSE
            g_error := 'GET CURSOR O_LIST(2)';
            OPEN o_list FOR
                SELECT lte.id_patient,
                       lte.id_episode,
                       lte.id_analysis_req,
                       lte.id_analysis_req_det,
                       h.id_harvest,
                       lte.id_analysis,
                       pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                 i_prof,
                                                                 pk_lab_tests_constant.g_analysis_alias,
                                                                 'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                 'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                                 NULL) desc_analysis,
                       lte.flg_status_det,
                       pk_sysdomain.get_domain(i_lang, i_prof, 'ANALYSIS_REQ_DET.FLG_STATUS', lte.flg_status_det, NULL) desc_status,
                       pk_date_utils.date_char_tsz(i_lang, lte.dt_req, i_prof.institution, i_prof.software) dt_req_hour
                  FROM harvest h, analysis_harvest ah, lab_tests_ea lte
                 WHERE h.barcode = i_barcode
                   AND h.id_harvest = ah.id_harvest
                   AND ah.id_analysis_req_det = lte.id_analysis_req_det
                   AND rownum = 1;
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
                                              'GET_PATIENT_BY_HARVEST_BARCODE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_patient_by_harvest_barcode;

    FUNCTION get_lab_test_to_schedule_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_order sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'LAB_TESTS_T181');
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT DISTINCT gtl.id_analysis_req,
                            lte.flg_status_req flg_status,
                            gtl.desc_analysis,
                            decode(lte.notes_scheduler, NULL, pk_lab_tests_constant.g_no, pk_lab_tests_constant.g_yes) flg_notes,
                            (SELECT pk_translation.get_translation(i_lang,
                                                                   'AB_SOFTWARE.CODE_SOFTWARE.' || gtl.id_software)
                               FROM dual) epis_type,
                            (SELECT pk_translation.get_translation(i_lang,
                                                                   'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                   gtl.id_institution)
                               FROM dual) desc_institution,
                            l_msg_order || ' ' || gtl.id_analysis_req num_order,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) prof_name,
                            pk_prof_utils.get_prof_speciality(i_lang,
                                                              profissional(lte.id_prof_writes,
                                                                           gtl.id_software,
                                                                           gtl.id_institution)) desc_speciality,
                            decode(lte.flg_status_req,
                                   pk_lab_tests_constant.g_analysis_tosched,
                                   pk_utils.get_status_string(i_lang,
                                                              i_prof,
                                                              '|' || pk_alert_constant.g_display_type_date_icon || '|' ||
                                                              pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                 lte.dt_req,
                                                                                                 pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) ||
                                                              '||#|' || pk_alert_constant.g_color_red || '||||&|Y',
                                                              '',
                                                              'ANALYSIS_REQ.FLG_STATUS',
                                                              pk_lab_tests_constant.g_analysis_pending),
                                   pk_utils.get_status_string(i_lang,
                                                              i_prof,
                                                              lte.status_str_req,
                                                              lte.status_msg_req,
                                                              lte.status_icon_req,
                                                              lte.status_flg_req)) status_string,
                            pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ.FLG_STATUS', lte.flg_status_req) rank,
                            pk_date_utils.date_send_tsz(i_lang, nvl(lte.dt_target, lte.dt_req), i_prof) dt_ord,
                            lte.id_patient,
                            pk_lab_tests_utils.get_lab_test_id_content(i_lang,
                                                                       i_prof,
                                                                       lte.id_analysis,
                                                                       lte.id_sample_type) id_content,
                            lte.id_prof_writes id_prof_req
              FROM (SELECT gtl.id_analysis_req,
                           pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                    i_prof,
                                                                    pk_lab_tests_constant.g_analysis_alias,
                                                                    'ANALYSIS.CODE_ANALYSIS.' || gtl.id_analysis,
                                                                    'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || gtl.id_sample_type,
                                                                    NULL) desc_analysis,
                           gtl.id_software,
                           gtl.id_institution,
                           gtl.id_analysis_req_det
                      FROM grid_task_lab gtl
                     WHERE gtl.id_patient = i_patient
                       AND gtl.flg_time_harvest IN
                           (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d)
                       AND gtl.flg_status_ard IN
                           (pk_lab_tests_constant.g_analysis_tosched, pk_lab_tests_constant.g_analysis_sched)
                       AND (EXISTS
                            (SELECT 1
                               FROM institution i
                              WHERE i.id_parent = (SELECT i.id_parent
                                                     FROM institution i
                                                    WHERE i.id_institution = i_prof.institution)
                                AND i.id_institution = gtl.id_institution) OR gtl.id_institution = i_prof.institution OR
                            (gtl.id_institution != i_prof.institution AND EXISTS
                             (SELECT 1
                                FROM transfer_institution ti
                               WHERE ti.flg_status = pk_alert_constant.g_flg_status_f
                                 AND ti.id_episode = gtl.id_episode
                                 AND ti.id_institution_dest = i_prof.institution)))) gtl
              JOIN lab_tests_ea lte
                ON gtl.id_analysis_req_det = lte.id_analysis_req_det
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
                                              'get_lab_test_to_schedule_list',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_lab_test_to_schedule_list;

    FUNCTION get_epis_active_ltech
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(4000);
        l_from       VARCHAR2(4000);
        v_where_cond VARCHAR2(4000);
        v_from_cond  VARCHAR2(4000);
    
        l_count NUMBER;
        aux_sql VARCHAR2(32000);
    
        l_limit            sys_config.desc_sys_config%TYPE := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_search_concluded sys_config.value%TYPE := pk_sysconfig.get_config('TECHNICIAN_PATIENT_SEARCH',
                                                                            i_prof.institution,
                                                                            i_prof.software);
        l_id_doc           sys_config.value%TYPE := pk_sysconfig.get_config('DOC_TYPE_ID',
                                                                            i_prof.institution,
                                                                            i_prof.software);
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_ret BOOLEAN;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
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
                    RAISE g_other_exception;
                END IF;
                l_where := l_where || v_where_cond;
            
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
    
        IF l_from IS NULL
        THEN
            l_from := 'patient pat';
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(x) ' || --
                   '  FROM (SELECT DISTINCT lte.id_analysis_req_det x ' || --
                   '          FROM lab_tests_ea       lte, ' || --
                   '               grid_task_lab      gtl, ' || --
                   '               episode            epis, ' || --
                   '               epis_info          ei, ' || --
                   '               visit              v, ' || --
                   l_from || ', ' || --
                   '               professional       p, ' || --
                   '               pat_soc_attributes psa, ' || --
                   '               epis_ext_sys       ees, ' || --
                   '               clin_record        cr, ' || --
                   '               doc_external       de ' || --
                   '         WHERE ((lte.flg_time_harvest = ''' || pk_lab_tests_constant.g_flg_time_e || ''') OR ' || --
                   '                       (lte.flg_time_harvest in (''' || pk_lab_tests_constant.g_flg_time_b ||
                   ''', ''' || pk_lab_tests_constant.g_flg_time_d || ''') ' ||
                   ' AND lte.dt_target BETWEEN :l_dt_begin AND :l_dt_end )) ' || --
                   '                   AND ((''' || l_search_concluded || ''' = ''' || pk_lab_tests_constant.g_no ||
                   ''' AND ' || --
                   '                       (lte.flg_status_det NOT IN (''' || pk_lab_tests_constant.g_analysis_cancel ||
                   ''', ''' || pk_lab_tests_constant.g_analysis_read || ''', ''' ||
                   pk_lab_tests_constant.g_analysis_result || ''') OR (lte.flg_status_det = ''' ||
                   pk_lab_tests_constant.g_analysis_result || ''' AND ei.id_software = ' ||
                   pk_alert_constant.g_soft_edis || '))) OR ' || --
                   '                       ''' || l_search_concluded || ''' = ''' || pk_lab_tests_constant.g_yes ||
                   ''') ' || --
                   '           AND (EXISTS ' || --
                   '                (SELECT 1 ' || --
                   '                   FROM institution i ' || --
                   '                  WHERE i.id_parent = (SELECT i.id_parent ' || --
                   '                                         FROM institution i ' || --
                   '                                        WHERE i.id_institution = ' || i_prof.institution || ') ' || --
                   '                    AND i.id_institution = lte.id_institution) OR lte.id_institution = ' ||
                   i_prof.institution || ') ' || --
                   '           AND lte.id_analysis_req_det = gtl.id_analysis_req_det(+) ' || --
                   '           AND lte.id_analysis_req = gtl.id_analysis_req(+) ' || --
                   '           AND lte.id_episode = epis.id_episode ' || --
                   '           AND lte.id_institution = epis.id_institution ' || --
                   '           AND epis.flg_status IN (''' || pk_alert_constant.g_epis_status_active || ''', ''' ||
                   pk_alert_constant.g_epis_status_temp || ''') ' || --
                   '           AND epis.id_episode = ei.id_episode ' || --
                   '           AND lte.id_visit = v.id_visit ' || --
                   '           AND lte.id_institution = v.id_institution ' || --
                   '           AND lte.id_patient = pat.id_patient ' || --
                   '           AND lte.id_prof_writes = p.id_professional ' || --
                   '           AND EXISTS (SELECT 1 ' || --
                   '                         FROM prof_room pr ' || --
                   '                        WHERE pr.id_professional = ' || i_prof.id || --
                   '                          AND pr.id_room = nvl(gtl.id_room_receive_tube, gtl.id_room_req)) ' || --
                   '           AND epis.id_episode = ees.id_episode(+) ' || --
                   '           AND epis.id_institution = ees.id_institution(+) ' || --
                   '           AND ees.id_external_sys(+) = ' || --
                   '               pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', ' || i_prof.institution || ', ' ||
                   i_prof.software || ') ' || --
                   '           AND lte.id_patient = cr.id_patient(+) ' || --
                   '           AND lte.id_institution = cr.id_institution(+) ' || --
                   '           AND lte.id_patient = de.id_patient(+) ' || --
                   '           AND de.id_doc_type(+) = ' || l_id_doc || --
                   '           AND de.flg_status(+) = ''' || pk_alert_constant.g_flg_status_a || ''' ' || --
                   '           AND lte.id_patient = psa.id_patient(+) ' || --
                   '           AND lte.id_institution = psa.id_institution(+) ' || --
                   l_where || --
                   '        UNION ALL ' || --
                   '        SELECT DISTINCT ei.id_episode x ' || --
                   '          FROM (SELECT s.id_schedule, sg.id_patient, s.id_instit_requests id_institution' || --
                   '                  FROM schedule s, ' || --
                   '											 sch_group sg, ' || --
                   '                       schedule_analysis sa ' || --
                   '								 WHERE s.id_schedule = sg.id_schedule ' || --
                   '								   AND s.id_schedule = sa.id_schedule(+)	 ' || --
                   '									 AND s.flg_sch_type = ''' || pk_schedule_common.g_sch_dept_flg_dep_type_anls || ''' ' || --
                   '									 AND s.dt_begin_tstz >= trunc(current_timestamp) AND s.dt_begin_tstz < trunc(current_timestamp) + 1 ' || --
                   '									 AND s.id_instit_requested = ' || i_prof.institution || --
                   '									 AND sa.id_analysis_req IS NULL ' || --
                   '									 AND s.flg_status != ''' || pk_schedule.g_sched_status_cancelled || ''') gtl, ' || --
                   '               episode epis, ' || --
                   '               epis_info ei, ' || --
                   '               visit v, ' || --
                   l_from || ', ' || --
                   '               professional p, ' || --
                   '               pat_soc_attributes psa, ' || --
                   '               epis_ext_sys ees, ' || --
                   '               clin_record cr, ' || --
                   '               doc_external de ' || --
                   '         WHERE gtl.id_schedule = ei.id_schedule ' || --
                   '           AND ei.id_episode = epis.id_episode ' || --
                   '           AND gtl.id_institution = epis.id_institution ' || --
                   '           AND epis.id_visit = v.id_visit ' || --
                   '           AND epis.id_institution = v.id_institution ' || --
                   '           AND gtl.id_patient = pat.id_patient ' || --
                   '           AND ei.id_professional = p.id_professional(+) ' || --
                   '           AND epis.id_episode = ees.id_episode(+) ' || --
                   '           AND epis.id_institution = ees.id_institution(+) ' || --
                   '           AND ees.id_external_sys(+) = ' || --
                   '               pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', ' || i_prof.institution || ', ' ||
                   i_prof.software || ') ' || --
                   '           AND gtl.id_patient = cr.id_patient(+) ' || --
                   '           AND gtl.id_institution = cr.id_institution(+) ' || --
                   '           AND gtl.id_patient = de.id_patient(+) ' || --
                   '           AND de.id_doc_type(+) = ' || l_id_doc || --
                   '           AND de.flg_status(+) = ''' || pk_alert_constant.g_flg_status_a || ''' ' || --
                   '           AND gtl.id_patient = psa.id_patient(+) ' || --
                   '           AND gtl.id_institution = psa.id_institution(+) ' || --
                   l_where || ')';
    
        dbms_output.put_line(aux_sql);
    
        g_error := 'GET EXECUTE IMMEDIATE COUNT';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING l_dt_begin, l_dt_end;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET SELECT';
        aux_sql := 'SELECT * ' || --
                   '  FROM (SELECT gtl.id_patient, ' || --
                   '               gtl.id_episode, ' || --
                   '               gtl.id_harvest, ' || --
                   '               0 id_analysis_req, ' || --
                   '               gtl.id_epis_type, ' || --
                   '               gtl.acuity, ' || --
                   '               gtl.rank_acuity, ' || --
                   '               gtl.triage_color_text color_text, ' || --
                   '               pk_edis_triage.get_epis_esi_level(' || i_lang || ', ' || --
                   '                                                 profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                                 gtl.id_episode, ' || --
                   '                                                 gtl.id_triage_color) esi_level, ' || --
                   '               pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                           gtl.dt_first_obs_tstz, ' || --
                   '                                           profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || ')) dt_first_obs, ' || --
                   '               pk_translation.get_translation(' || i_lang ||
                   ', ''AB_SOFTWARE.CODE_SOFTWARE.'' || gtl.id_software) epis_type, ' || --
                   '               pk_translation.get_translation(' || i_lang ||
                   ', ''AB_INSTITUTION.CODE_INSTITUTION.'' || gtl.id_institution) desc_institution, ' || --
                   '               pk_patient.get_pat_name(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '), ' || --
                   '                                       gtl.id_patient, ' || --
                   '                                       gtl.id_episode, ' || --
                   '                                       NULL) desc_patient, ' || --
                   '               pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || --
                   '                                               profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                               gtl.id_patient) pat_ndo, ' || --
                   '               pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || --
                   '                                                  profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                                  gtl.id_patient) pat_nd_icon, ' || --
                   '               decode(gtl.id_analysis,  ' || --
                   '                      NULL, ' || --
                   '                      NULL, ' || --
                   '                      pk_lab_tests_utils.get_alias_translation(' || i_lang || ', ' || --
                   '                                                        profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ''' || pk_lab_tests_constant.g_analysis_alias ||
                   ''', ' ||
                   '                                                        ''ANALYSIS.CODE_ANALYSIS.'' || gtl.id_analysis, ' || --
                   '                                                        ''SAMPLE_TYPE.CODE_SAMPLE_TYPE.'' || gtl.id_sample_type, ' || --
                   '                                                        NULL)) || ' || --
                   '               decode(gtl.id_sample_recipient, ' || --
                   '                      NULL, ' || --
                   '                      NULL, ' || --
                   '                      '' / '' || ' || --
                   '                      pk_translation.get_translation(' || i_lang || ', ' || --
                   '                                                     ''SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.'' || gtl.id_sample_recipient)) desc_analysis, ' || --
                   '               gtl.request col_request, ' || --
                   '               gtl.harvest col_harvest, ' || --
                   '               gtl.transport col_transport, ' || --
                   '               gtl.execute col_execute, ' || --
                   '               decode(gtl.flg_status_ard, ' || --
                   '                      ''' || pk_lab_tests_constant.g_analysis_result || ''', ' || --
                   '                      pk_sysdomain.get_img(' || i_lang ||
                   ', ''ANALYSIS_REQ_DET.FLG_STATUS'', gtl.flg_status_ard), ' || --
                   '                      NULL) col_complete, ' || --
                   '               pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || --
                   '                                               profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                               gtl.id_patient, ' || --
                   '                                               gtl.id_episode, ' || --
                   '                                               NULL) order_name, ' || --
                   '               decode(gtl.flg_status_ard, ' || --
                   '                      ''' || pk_lab_tests_constant.g_analysis_req || ''', ' || --
                   '                      row_number() over(ORDER BY gtl.id_episode, ' || --
                   '                           pk_sysdomain.get_rank(' || i_lang ||
                   ', ''ANALYSIS_REQ_DET.FLG_STATUS'', gtl.flg_status_ard), ' || --
                   '                           coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)), ' || --
                   '                      ''' || pk_lab_tests_constant.g_analysis_pending || ''', ' || --
                   '                      row_number() over(ORDER BY gtl.id_episode, ' || --
                   '                           pk_sysdomain.get_rank(' || i_lang ||
                   ', ''ANALYSIS_REQ_DET.FLG_STATUS'', gtl.flg_status_ard), ' || --
                   '                           coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)), ' || --
                   '                      row_number() over(ORDER BY gtl.id_episode, ' || --
                   '                           pk_sysdomain.get_rank(' || i_lang ||
                   ', ''ANALYSIS_REQ_DET.FLG_STATUS'', gtl.flg_status_ard), ' || --
                   '                           coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz) DESC)) rank, ' || --
                   '               pk_date_utils.date_send_tsz(' || i_lang || ', gtl.dt_order, profissional(' ||
                   i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ')) dt_ord, ' || --
                   '               pk_date_utils.date_send_tsz(' || i_lang || ', current_timestamp, ' ||
                   i_prof.institution || ', ' || i_prof.software || ') dt_server ' || --
                   '          FROM (SELECT DISTINCT gtl.id_patient, ' || --
                   '                                gtl.id_episode, ' || --
                   '                                gtl.id_epis_type, ' || --
                   '                                gtl.id_harvest, ' || --
                   '                                gtl.acuity, ' || --
                   '                                gtl.rank_acuity, ' || --
                   '                                gtl.triage_color_text, ' || --
                   '                                gtl.id_triage_color, ' || --
                   '                                gtl.dt_first_obs_tstz, ' || --
                   '                                gtl.id_software, ' || --
                   '                                gtl.id_institution, ' || --
                   '                                lte.id_analysis, ' || --
                   '                                lte.id_sample_type, ' || --
                   '                                gtl.id_sample_recipient, ' || --
                   '                                gtl.request, ' || --
                   '                                gtl.harvest, ' || --
                   '                                gtl.transport, ' || --
                   '                                gtl.execute, ' || --
                   '                                gtl.id_announced_arrival, ' || --
                   '                                gtl.flg_status_ard, ' || --
                   '                                gtl.dt_pend_req_tstz, ' || --
                   '                                gtl.dt_target_tstz, ' || --
                   '                                gtl.dt_req_tstz, ' || --
                   '                                gtl.dt_order ' || --
                   '                  FROM lab_tests_ea       lte, ' || --
                   '                       grid_task_lab      gtl, ' || --
                   '                       episode            epis, ' || --
                   '                       epis_info          ei, ' || --
                   '                       visit              v, ' || --
                   l_from || ', ' || --
                   '                       professional       p, ' || --
                   '                       pat_soc_attributes psa, ' || --
                   '                       epis_ext_sys       ees, ' || --
                   '                       clin_record        cr, ' || --
                   '                       doc_external       de ' || --
                   '                 WHERE ((lte.flg_time_harvest = ''' || pk_lab_tests_constant.g_flg_time_e ||
                   ''') OR ' || --
                   '                       (lte.flg_time_harvest in (''' || pk_lab_tests_constant.g_flg_time_b ||
                   ''', ''' || pk_lab_tests_constant.g_flg_time_d || ''' ) ' ||
                   ' AND lte.dt_target BETWEEN :l_dt_begin AND :l_dt_end )) ' || --
                   '                   AND ((''' || l_search_concluded || ''' = ''' || pk_lab_tests_constant.g_no ||
                   ''' AND ' || --
                   '                       (lte.flg_status_det NOT IN (''' || pk_lab_tests_constant.g_analysis_cancel ||
                   ''', ''' || pk_lab_tests_constant.g_analysis_read || ''', ''' ||
                   pk_lab_tests_constant.g_analysis_result || ''') OR (lte.flg_status_det = ''' ||
                   pk_lab_tests_constant.g_analysis_result || ''' AND ei.id_software = ' ||
                   pk_alert_constant.g_soft_edis || '))) OR ' || --
                   '                       ''' || l_search_concluded || ''' = ''' || pk_lab_tests_constant.g_yes ||
                   ''') ' || --
                   '                   AND (EXISTS ' || --
                   '                        (SELECT 1 ' || --
                   '                           FROM institution i ' || --
                   '                          WHERE i.id_parent = (SELECT i.id_parent ' || --
                   '                                                 FROM institution i ' || --
                   '                                                WHERE i.id_institution = ' || i_prof.institution || ') ' || --
                   '                            AND i.id_institution = lte.id_institution) OR lte.id_institution = ' ||
                   i_prof.institution || ') ' || --
                   '                   AND lte.id_analysis_req_det = gtl.id_analysis_req_det(+) ' || --
                   '                   AND lte.id_analysis_req = gtl.id_analysis_req(+) ' || --
                   '                   AND lte.id_episode = epis.id_episode ' || --
                   '                   AND lte.id_institution = epis.id_institution ' || --
                   '                   AND epis.flg_status IN (''' || pk_alert_constant.g_epis_status_active ||
                   ''', ''' || pk_alert_constant.g_epis_status_temp || ''') ' || --
                   '                   AND epis.id_episode = ei.id_episode ' || --
                   '                   AND lte.id_visit = v.id_visit ' || --
                   '                   AND v.id_visit = epis.id_visit ' || --
                   '                   AND v.id_institution = lte.id_institution ' || --
                   '                   AND lte.id_patient = pat.id_patient ' || --
                   '                   AND lte.id_prof_writes = p.id_professional ' || --
                   '                   AND EXISTS (SELECT 1 ' || --
                   '                          FROM prof_room pr ' || --
                   '                         WHERE pr.id_professional = ' || i_prof.id || ' ' || --
                   '                           AND pr.id_room = nvl(gtl.id_room_receive_tube, gtl.id_room_req)) ' || --
                   '                   AND epis.id_episode = ees.id_episode(+) ' || --
                   '                   AND epis.id_institution = ees.id_institution(+) ' || --
                   '                   AND ees.id_external_sys(+) = ' || --
                   '                       pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', ' || i_prof.institution || ', ' ||
                   i_prof.software || ') ' || --
                   '                   AND lte.id_patient = cr.id_patient(+) ' || --
                   '                   AND lte.id_institution = cr.id_institution(+) ' || --
                   '                   AND lte.id_patient = de.id_patient(+) ' || --
                   '                   AND de.id_doc_type(+) = ' || l_id_doc || --
                   '                   AND de.flg_status(+) = ''' || pk_alert_constant.g_flg_status_a || ''' ' || --
                   '                   AND lte.id_patient = psa.id_patient(+) ' || --
                   '                   AND lte.id_institution = psa.id_institution(+) ' || --
                   l_where || --
                   '                UNION ALL ' || --
                   '                SELECT DISTINCT gtl.id_patient, ' || --
                   '                                NULL               id_harvest, ' || --
                   '                                ei.id_episode, ' || --
                   '                                ' || pk_alert_constant.g_epis_type_lab || ' id_epis_type, ' || --
                   '                                NULL               acuity, ' || --
                   '                                NULL               rank_acuity, ' || --
                   '                                NULL               triage_color_text, ' || --
                   '                                NULL               id_triage_color, ' || --
                   '                                NULL               dt_first_obs_tstz, ' || --
                   '                                ' || pk_alert_constant.g_soft_labtech || '  id_software, ' || --
                   '                                gtl.id_institution, ' || --
                   '                                NULL               id_analysis, ' || --
                   '                                NULL               id_sample_type, ' || --
                   '                                NULL               id_sample_recipient, ' || --
                   '                                NULL               request, ' || --
                   '                                NULL               harvest, ' || --
                   '                                NULL               transport, ' || --
                   '                                NULL               execute, ' || --
                   '                                NULL               id_announced_arrival, ' || --
                   '                                NULL               flg_status_ard, ' || --
                   '                                NULL               dt_pend_req_tstz, ' || --
                   '                                gtl.dt_target_tstz, ' || --
                   '                                NULL               dt_req_tstz, ' || --
                   '                                NULL               dt_order ' || --
                   '                  FROM (SELECT s.id_schedule, ' || --
                   '                               sg.id_patient, ' || --
                   '                               s.id_instit_requests id_institution, ' || --
                   '                               s.dt_begin_tstz dt_target_tstz ' || --
                   '                          FROM schedule s, ' || --
                   '									        		 sch_group sg, ' || --
                   '                               schedule_analysis sa ' || --
                   '								         WHERE s.id_schedule = sg.id_schedule ' || --
                   '								           AND s.id_schedule = sa.id_schedule(+)	 ' || --
                   '									         AND s.flg_sch_type = ''' || pk_schedule_common.g_sch_dept_flg_dep_type_anls ||
                   ''' ' || --
                   '									         AND s.dt_begin_tstz >= trunc(current_timestamp) AND s.dt_begin_tstz < trunc(current_timestamp) + 1 ' || --
                   '									         AND s.id_instit_requested = ' || i_prof.institution || --
                   '									         AND sa.id_analysis_req IS NULL ' || --
                   '									         AND s.flg_status != ''' || pk_schedule.g_sched_status_cancelled || ''') gtl, ' || --
                   '                       episode epis, ' || --
                   '                       epis_info ei, ' || --
                   '                       visit v, ' || --
                   l_from || ', ' || --
                   '                       professional p, ' || --
                   '                       pat_soc_attributes psa, ' || --
                   '                       epis_ext_sys ees, ' || --
                   '                       clin_record cr, ' || --
                   '                       doc_external de ' || --
                   '                 WHERE gtl.id_schedule = ei.id_schedule ' || --
                   '                   AND epis.id_institution = gtl.id_institution ' || --
                   '                   AND epis.id_episode = ei.id_episode ' || --
                   '                   AND epis.id_visit = v.id_visit ' || --
                   '                   AND v.id_institution = gtl.id_institution ' || --
                   '                   AND gtl.id_patient = pat.id_patient ' || --
                   '                   AND ei.id_professional = p.id_professional(+) ' || --
                   '                   AND epis.id_episode = ees.id_episode(+) ' || --
                   '                   AND epis.id_institution = ees.id_institution(+) ' || --
                   '                   AND ees.id_external_sys(+) = ' || --
                   '                       pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', ' || i_prof.institution || ', ' ||
                   i_prof.software || ') ' || --
                   '                   AND gtl.id_patient = cr.id_patient(+) ' || --
                   '                   AND gtl.id_institution = cr.id_institution(+) ' || --
                   '                   AND gtl.id_patient = de.id_patient(+) ' || --
                   '                   AND de.id_doc_type(+) = ' || l_id_doc || --
                   '                   AND de.flg_status(+) = ''' || pk_alert_constant.g_flg_status_a || ''' ' || --
                   '                   AND gtl.id_patient = psa.id_patient(+) ' || --
                   '                   AND gtl.id_institution = psa.id_institution(+) ' || --
                   l_where || ') gtl ' || --
                   '         ORDER BY rank_acuity) ' || --
                   ' WHERE rownum < ' || l_limit;
    
        dbms_output.put_line(l_from);
        dbms_output.put_line(l_limit);
        dbms_output.put_line(l_dt_begin);
        dbms_output.put_line(l_dt_end);
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR aux_sql
            USING l_dt_begin, l_dt_end;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_list);
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_ACTIVE_LTECH', o_error);
        
            RETURN TRUE;
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_list);
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_ACTIVE_LTECH', o_error);
        
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_ACTIVE_LTECH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_epis_active_ltech;

    FUNCTION get_epis_inactive_ltech
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(4000);
        l_from       VARCHAR2(4000);
        v_where_cond VARCHAR2(4000);
        v_from_cond  VARCHAR2(4000);
    
        l_count NUMBER;
        aux_sql VARCHAR2(32000);
    
        l_limit  sys_config.desc_sys_config%TYPE := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_id_doc sys_config.value%TYPE := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
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
                    RAISE g_other_exception;
                END IF;
                l_where := l_where || v_where_cond;
            
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
    
        IF l_from IS NULL
        THEN
            l_from := 'patient pat';
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(DISTINCT epis.id_episode) ' || --
                   '  FROM lab_tests_ea       lte, ' || --
                   '       analysis_req_det   ard, ' || --
                   '       grid_task_lab      gtl, ' || --
                   '       episode            epis, ' || --
                   '       epis_info          epi, ' || --
                   '       visit              v, ' || --
                   l_from || ', ' || --
                   '       professional       p, ' || --
                   '       pat_soc_attributes psa, ' || --
                   '       epis_ext_sys       ees, ' || --
                   '       clin_record        cr, ' || --
                   '       doc_external       de ' || --
                   ' WHERE ((lte.flg_time_harvest = ''E'') OR ' || --
                   '       (lte.flg_time_harvest = ''B'' AND lte.dt_target BETWEEN ''' || l_dt_begin || ''' AND ''' ||
                   l_dt_end || ''')) ' || --
                   '   AND (lte.flg_status_det NOT IN (''C'', ''L'', ''F'') OR (lte.flg_status_det = ''F'' AND epi.id_software = 8)) ' || --
                   '   AND (EXISTS ' || --
                   '         (SELECT 1 ' || --
                   '            FROM institution i ' || --
                   '           WHERE i.id_parent = (SELECT i.id_parent ' || --
                   '                                  FROM institution i ' || --
                   '                                 WHERE i.id_institution = ' || i_prof.institution || ') ' || --
                   '             AND i.id_institution = lte.id_institution) OR lte.id_institution = ' ||
                   i_prof.institution || ') ' || --
                   '   AND lte.id_analysis_req_det = ard.id_analysis_req_det ' || --
                   '   AND lte.id_analysis_req_det = gtl.id_analysis_req_det(+) ' || --
                   '   AND lte.id_analysis_req = gtl.id_analysis_req(+) ' || --
                   '   AND lte.id_episode = epis.id_episode ' || --
                   '   AND epis.flg_status = ''T'' ' || --
                   '   AND epis.id_institution = lte.id_institution ' || --
                   '   AND epis.id_episode = epi.id_episode ' || --
                   '   AND lte.id_visit = v.id_visit ' || --
                   '   AND v.id_visit = epis.id_visit ' || --
                   '   AND v.id_institution = lte.id_institution ' || --
                   '   AND lte.id_patient = pat.id_patient ' || --
                   '   AND pat.id_patient = v.id_patient ' || --
                   '   AND lte.id_prof_writes = p.id_professional ' || --
                   '   AND (EXISTS (SELECT 0 ' || --
                   '                  FROM prof_room pr ' || --
                   '                 WHERE pr.id_professional = ' || i_prof.id || --
                   '                   AND ard.id_room = pr.id_room) OR ard.id_room IS NULL) ' || --
                   '   AND epis.id_episode = ees.id_episode(+) ' || --
                   '   AND (lte.id_institution = ees.id_institution OR ees.id_institution IS NULL) ' || --
                   '   AND ees.id_external_sys(+) = pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', ' ||
                   i_prof.institution || ', ' || i_prof.software || ') ' || --
                   '   AND pat.id_patient = cr.id_patient(+) ' || --
                   '   AND (lte.id_institution = cr.id_institution OR cr.id_institution IS NULL) ' || --
                   '   AND pat.id_patient = de.id_patient(+) ' || --
                   '   AND de.id_doc_type(+) = ' || l_id_doc || --
                   '   AND de.flg_status(+) = ''A'' ' || --
                   '   AND pat.id_patient = psa.id_patient(+) ' || --
                   '   AND (lte.id_institution = psa.id_institution OR psa.id_institution IS NULL) ' || --
                   l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count;
    
        pk_alertlog.log_info('l_count - LAB- ' || l_count);
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        aux_sql := 'SELECT * FROM (' || 'SELECT DISTINCT epi.triage_rank_acuity rank, ' || --
                   '                epi.triage_acuity acuity, ' || --
                   '                epi.triage_rank_acuity rank_acuity, ' || --
                   '                epi.triage_color_text color_text, ' || --
                   '                pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                            epi.dt_first_obs_tstz, ' || --
                   '                                            profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || ')) dt_first_obs, ' || --
                   '                pk_message.get_message(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ', ' || i_prof.institution ||
                   ', epi.id_software), ' || --
                   '                                       ''IMAGE_T009'') epis_type, ' || --
                   '                pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || --
                   '                                                profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                                pat.id_patient, ' || --
                   '                                                epis.id_episode, ' || --
                   '                                                NULL) order_name, ' || --
                   '                pk_patient.get_pat_name(' || i_lang || ', ' || --
                   '                                        profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '), ' || --
                   '                                        pat.id_patient, ' || --
                   '                                        epis.id_episode, ' || --
                   '                                        NULL) desc_patient, ' || --
                   '                pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || --
                   '                                                profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                                pat.id_patient) pat_ndo, ' || --
                   '                pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || --
                   '                                                   profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                                   pat.id_patient) pat_nd_icon, ' || --
                   '                pk_lab_tests_utils.get_alias_translation(' || i_lang || ', ' || --
                   '                                                profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || pk_lab_tests_constant.g_analysis_alias || ', ' ||
                   ', ''ANALYSIS.CODE_ANALYSIS.'' || lte.id_analysis, ''SAMPLE_TYPE.CODE_SAMPLE_TYPE.'' || lte.id_sample_type, NULL) || ' || --
                   '                decode(gtl.id_sample_recipient, ' || --
                   '                       NULL, ' || --
                   '                       NULL, ' || --
                   '                       '' / '' || pk_translation.get_translation(' || i_lang || ', ' || --
                   '                                                               ''SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.'' || ' || --
                   '                                                               gtl.id_sample_recipient)) desc_analysis, ' || --
                   '                gtl.request col_request, ' || --
                   '                gtl.harvest col_harvest, ' || --
                   '                gtl.transport col_transport, ' || --
                   '                gtl.execute col_execute, ' || --
                   '                gtl.complete col_complete, ' || --
                   '                gtl.id_harvest, ' || --
                   '                pat.id_patient, ' || --
                   '                epis.id_episode, ' || --
                   '                lte.id_analysis_req, ' || --
                   '                lte.id_analysis_req_det, ' || --
                   '                pk_date_utils.date_send_tsz(' || i_lang || ', current_timestamp, ' ||
                   i_prof.institution || ', ' || i_prof.software || ') dt_server, ' || --
                   '                pk_edis_triage.get_epis_esi_level(' || i_lang || ', ' || --
                   '                                                      profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '                                                      epis.id_episode, ' || --
                   '                                                      epi.id_triage_color) esi_level ' || --
                   '  FROM lab_tests_ea       lte, ' || --
                   '       analysis_req_det   ard, ' || --
                   '       grid_task_lab      gtl, ' || --
                   '       episode            e, ' || --
                   '       epis_info          ei, ' || --
                   '       visit              v, ' || --
                   l_from || ', ' || --
                   '       professional       p, ' || --
                   '       pat_soc_attributes psa, ' || --
                   '       epis_ext_sys       ees, ' || --
                   '       clin_record        cr, ' || --
                   '       doc_external       de ' || --
                   ' WHERE ((lte.flg_time_harvest = ''E'') OR ' || --
                   '       (lte.flg_time_harvest = ''B'' AND lte.dt_target BETWEEN ''' || l_dt_begin || ''' AND ''' ||
                   l_dt_end || ''')) ' || --
                   '   AND (lte.flg_status_det NOT IN (''C'', ''L'', ''F'') OR (lte.flg_status_det = ''F'' AND epi.id_software = 8)) ' || --
                   '   AND (EXISTS ' || --
                   '         (SELECT 1 ' || --
                   '            FROM institution i ' || --
                   '           WHERE i.id_parent = (SELECT i.id_parent ' || --
                   '                                  FROM institution i ' || --
                   '                                 WHERE i.id_institution = ' || i_prof.institution || ') ' || --
                   '             AND i.id_institution = lte.id_institution) OR lte.id_institution = ' ||
                   i_prof.institution || ') ' || --
                   '   AND lte.id_analysis_req_det = ard.id_analysis_req_det ' || --
                   '   AND lte.id_analysis_req_det = gtl.id_analysis_req_det(+) ' || --
                   '   AND lte.id_analysis_req = gtl.id_analysis_req(+) ' || --
                   '   AND lte.id_episode = epis.id_episode ' || --
                   '   AND epis.flg_status = ''I'' ' || --
                   '   AND epis.id_institution = lte.id_institution ' || --
                   '   AND epis.id_episode = epi.id_episode ' || --
                   '   AND lte.id_visit = v.id_visit ' || --
                   '   AND v.id_visit = epis.id_visit ' || --
                   '   AND v.id_institution = lte.id_institution ' || --
                   '   AND lte.id_patient = pat.id_patient ' || --
                   '   AND pat.id_patient = v.id_patient ' || --
                   '   AND lte.id_prof_writes = p.id_professional ' || --
                   '   AND (EXISTS (SELECT 0 ' || --
                   '                  FROM prof_room pr ' || --
                   '                 WHERE pr.id_professional = ' || i_prof.id || --
                   '                   AND ard.id_room = pr.id_room) OR ard.id_room IS NULL) ' || --
                   '   AND epis.id_episode = ees.id_episode(+) ' || --
                   '   AND (lte.id_institution = ees.id_institution OR ees.id_institution IS NULL) ' || --
                   '   AND ees.id_external_sys(+) = pk_sysconfig.get_config(''ID_EXTERNAL_SYS'', ' ||
                   i_prof.institution || ', ' || i_prof.software || ') ' || --
                   '   AND pat.id_patient = cr.id_patient(+) ' || --
                   '   AND (lte.id_institution = cr.id_institution OR cr.id_institution IS NULL) ' || --
                   '   AND pat.id_patient = de.id_patient(+) ' || --
                   '   AND de.id_doc_type(+) = ' || l_id_doc || --
                   '   AND de.flg_status(+) = ''A'' ' || --
                   '   AND pat.id_patient = psa.id_patient(+) ' || --
                   '   AND (lte.id_institution = psa.id_institution OR psa.id_institution IS NULL) ' || --
                   l_where || ' ORDER BY rank_acuity) WHERE rownum < ' || l_limit;
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR aux_sql;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_INACTIVE_LTECH', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_list);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_INACTIVE_LTECH', o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_INACTIVE_LTECH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_epis_inactive_ltech;

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
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_collect_pending sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('HARVEST_PENDING_REQ', l_prof);
        l_num_days_back   sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK',
                                                                           l_prof);
    
        --FILTER_BIND
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        g_sysdate_char VARCHAR(50 CHAR);
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(l_lang, g_sysdate_tstz, l_prof);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_collect_pending', l_collect_pending);
    
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
    
        DELETE grid_task_lab gtl
         WHERE gtl.flg_status_ard = pk_lab_tests_constant.g_analysis_result
           AND gtl.dt_req_tstz <= l_dt_begin - INTERVAL '1'
         DAY
           AND gtl.id_epis_type != pk_lab_tests_constant.g_episode_type_lab;
    
        DELETE grid_task_lab gtl
         WHERE gtl.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtl.id_epis_type != pk_lab_tests_constant.g_episode_type_lab;
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        DELETE grid_task_lab gtl
         WHERE gtl.flg_status_ard IN (pk_lab_tests_constant.g_analysis_result,
                                      pk_lab_tests_constant.g_analysis_read,
                                      pk_lab_tests_constant.g_analysis_cancel)
           AND gtl.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
           AND gtl.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtl.id_epis_type = pk_lab_tests_constant.g_episode_type_lab;
    
        COMMIT;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz);
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        pk_context_api.set_parameter('i_dt_begin', l_dt_begin);
        pk_context_api.set_parameter('i_dt_end', l_dt_end);
    
        g_error := 'PK_LAB_TECH, parameter:' || i_name || ' not found';
        CASE i_name
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_id_i_prof' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_id_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_id_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_sysdate_char' THEN
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
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_LAB_TECH',
                                              i_function => 'INIT_PARAMS_GRID',
                                              o_error    => o_error);
    END init_params_grid;

    FUNCTION get_col_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_status        IN analysis_req_det.flg_status%TYPE,
        i_flg_time_harvest  IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_referral      IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_h      IN harvest.flg_status%TYPE,
        i_flg_status_result IN analysis_result.flg_status%TYPE,
        i_dt_req_tstz       IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz  IN analysis_req.dt_pend_req_tstz%TYPE,
        i_dt_target_tstz    IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(100);
    BEGIN
    
        SELECT CASE
                   WHEN i_flg_status = pk_lab_tests_constant.g_analysis_req
                        OR i_flg_status = pk_lab_tests_constant.g_analysis_pending THEN
                    ('0' ||
                    pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 i_flg_status,
                                                                                                 i_flg_referral,
                                                                                                 i_flg_status_h,
                                                                                                 i_flg_status_result,
                                                                                                 NULL,
                                                                                                 i_dt_req_tstz,
                                                                                                 i_dt_pend_req_tstz,
                                                                                                 i_dt_target_tstz),
                                                pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 i_flg_status,
                                                                                                 i_flg_referral,
                                                                                                 i_flg_status_h,
                                                                                                 i_flg_status_result,
                                                                                                 NULL,
                                                                                                 i_dt_req_tstz,
                                                                                                 i_dt_pend_req_tstz,
                                                                                                 i_dt_target_tstz),
                                                pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                  i_prof,
                                                                                                  i_id_episode,
                                                                                                  i_flg_time_harvest,
                                                                                                  i_flg_status,
                                                                                                  i_flg_referral,
                                                                                                  i_flg_status_h,
                                                                                                  i_flg_status_result,
                                                                                                  NULL,
                                                                                                  i_dt_req_tstz,
                                                                                                  i_dt_pend_req_tstz,
                                                                                                  i_dt_target_tstz),
                                                pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 i_flg_status,
                                                                                                 i_flg_referral,
                                                                                                 i_flg_status_h,
                                                                                                 i_flg_status_result,
                                                                                                 NULL,
                                                                                                 i_dt_req_tstz,
                                                                                                 i_dt_pend_req_tstz,
                                                                                                 i_dt_target_tstz)))
                   ELSE
                    ''
               END
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN '';
    END get_col_request;

    FUNCTION get_col_harvest
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_status            IN analysis_req_det.flg_status%TYPE,
        i_flg_time_harvest      IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_h          IN harvest.flg_status%TYPE,
        i_dt_req_tstz           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz      IN analysis_req.dt_pend_req_tstz%TYPE,
        i_dt_target_tstz        IN analysis_req_det.dt_target_tstz%TYPE,
        i_dt_harvest            IN harvest.dt_harvest_tstz%TYPE,
        i_dt_begin_tstz_m       IN movement.dt_begin_tstz%TYPE,
        i_dt_mov_begin_tstz     IN movement.dt_begin_tstz%TYPE,
        i_dt_end_tstz           IN movement.dt_end_tstz%TYPE,
        i_dt_lab_reception_tstz IN movement.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(100);
    BEGIN
    
        SELECT CASE
                   WHEN i_flg_status = pk_lab_tests_constant.g_analysis_ongoing
                        AND i_flg_status_h = pk_lab_tests_constant.g_analysis_result_preliminary THEN
                    ('0' ||
                    pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz),
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz),
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz)),
                                                pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz),
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz),
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz)),
                                                pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                  i_prof,
                                                                                                  i_id_episode,
                                                                                                  i_flg_time_harvest,
                                                                                                  pk_lab_tests_constant.g_analysis_req,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  coalesce(i_dt_harvest,
                                                                                                           i_dt_pend_req_tstz,
                                                                                                           i_dt_target_tstz,
                                                                                                           i_dt_req_tstz),
                                                                                                  coalesce(i_dt_harvest,
                                                                                                           i_dt_pend_req_tstz,
                                                                                                           i_dt_target_tstz,
                                                                                                           i_dt_req_tstz),
                                                                                                  coalesce(i_dt_harvest,
                                                                                                           i_dt_pend_req_tstz,
                                                                                                           i_dt_target_tstz,
                                                                                                           i_dt_req_tstz)),
                                                pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz),
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz),
                                                                                                 coalesce(i_dt_harvest,
                                                                                                          i_dt_pend_req_tstz,
                                                                                                          i_dt_target_tstz,
                                                                                                          i_dt_req_tstz))))
                   WHEN i_flg_status = pk_lab_tests_constant.g_analysis_ongoing
                        AND i_flg_status_h = pk_lab_tests_constant.g_analysis_collected THEN
                    ('0' ||
                    pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 i_dt_harvest,
                                                                                                 i_dt_harvest,
                                                                                                 i_dt_harvest),
                                                pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 i_dt_harvest,
                                                                                                 i_dt_harvest,
                                                                                                 i_dt_harvest),
                                                pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                  i_prof,
                                                                                                  i_id_episode,
                                                                                                  i_flg_time_harvest,
                                                                                                  pk_lab_tests_constant.g_analysis_req,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  i_dt_harvest,
                                                                                                  i_dt_harvest,
                                                                                                  i_dt_harvest),
                                                pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 i_dt_harvest,
                                                                                                 i_dt_harvest,
                                                                                                 i_dt_harvest)))
                   WHEN i_flg_status = pk_lab_tests_constant.g_analysis_ongoing
                        AND i_flg_status_h = pk_lab_tests_constant.g_analysis_transport THEN
                    ('0' ||
                    pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                  i_prof,
                                                                                                  i_id_episode,
                                                                                                  i_flg_time_harvest,
                                                                                                  pk_lab_tests_constant.g_analysis_req,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  coalesce(i_dt_begin_tstz_m,
                                                                                                           i_dt_mov_begin_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_begin_tstz_m,
                                                                                                           i_dt_mov_begin_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_begin_tstz_m,
                                                                                                           i_dt_mov_begin_tstz,
                                                                                                           i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest))))
                   WHEN i_flg_status = pk_lab_tests_constant.g_analysis_ongoing
                        AND i_flg_status_h = pk_lab_tests_constant.g_analysis_result THEN
                    ('0' ||
                    pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                  i_prof,
                                                                                                  i_id_episode,
                                                                                                  i_flg_time_harvest,
                                                                                                  pk_lab_tests_constant.g_analysis_req,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  coalesce(i_dt_end_tstz,
                                                                                                           i_dt_lab_reception_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_end_tstz,
                                                                                                           i_dt_lab_reception_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_end_tstz,
                                                                                                           i_dt_lab_reception_tstz,
                                                                                                           i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest))))
                   ELSE
                    ''
               END
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN '';
    END get_col_harvest;

    FUNCTION get_col_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_status        IN analysis_req_det.flg_status%TYPE,
        i_flg_time_harvest  IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_h      IN harvest.flg_status%TYPE,
        i_dt_begin_tstz_m   IN movement.dt_begin_tstz%TYPE,
        i_dt_mov_begin_tstz IN movement.dt_begin_tstz%TYPE,
        i_dt_harvest        IN harvest.dt_harvest_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(100);
    BEGIN
    
        SELECT CASE
                   WHEN i_flg_status_h = pk_lab_tests_constant.g_analysis_transport THEN
                    ('0' ||
                    pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                  i_prof,
                                                                                                  i_id_episode,
                                                                                                  i_flg_time_harvest,
                                                                                                  pk_lab_tests_constant.g_analysis_req,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  coalesce(i_dt_begin_tstz_m,
                                                                                                           i_dt_mov_begin_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_begin_tstz_m,
                                                                                                           i_dt_mov_begin_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_begin_tstz_m,
                                                                                                           i_dt_mov_begin_tstz,
                                                                                                           i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_begin_tstz_m,
                                                                                                          i_dt_mov_begin_tstz,
                                                                                                          i_dt_harvest))))
                   ELSE
                    ''
               END
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN '';
    END get_col_transport;

    FUNCTION get_col_execute
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_time_harvest      IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_h          IN harvest.flg_status%TYPE,
        i_dt_end_tstz           IN movement.dt_end_tstz%TYPE,
        i_dt_lab_reception_tstz IN movement.dt_begin_tstz%TYPE,
        i_dt_harvest            IN harvest.dt_harvest_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(100);
    BEGIN
    
        SELECT CASE
                   WHEN i_flg_status_h = pk_lab_tests_constant.g_analysis_transport THEN
                    ('0' ||
                    pk_utils.get_status_string(i_lang,
                                                i_prof,
                                                pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                  i_prof,
                                                                                                  i_id_episode,
                                                                                                  i_flg_time_harvest,
                                                                                                  pk_lab_tests_constant.g_analysis_req,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  NULL,
                                                                                                  coalesce(i_dt_end_tstz,
                                                                                                           i_dt_lab_reception_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_end_tstz,
                                                                                                           i_dt_lab_reception_tstz,
                                                                                                           i_dt_harvest),
                                                                                                  coalesce(i_dt_end_tstz,
                                                                                                           i_dt_lab_reception_tstz,
                                                                                                           i_dt_harvest)),
                                                pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                 i_prof,
                                                                                                 i_id_episode,
                                                                                                 i_flg_time_harvest,
                                                                                                 pk_lab_tests_constant.g_analysis_req,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 NULL,
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest),
                                                                                                 coalesce(i_dt_end_tstz,
                                                                                                          i_dt_lab_reception_tstz,
                                                                                                          i_dt_harvest))))
                   ELSE
                    ''
               END
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            RETURN '';
    END get_col_execute;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tech;
/
