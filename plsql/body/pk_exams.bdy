/*-- Last Change Revision: $Rev: 2027132 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_exams IS

    FUNCTION set_exam_grid_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type exam.flg_type%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT e.flg_type
              INTO l_flg_type
              FROM exam_req_det erd, exam e
             WHERE erd.id_exam_req_det = i_exam_req_det
               AND erd.id_exam = e.id_exam;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_type := NULL;
        END;
    
        IF l_flg_type = pk_exam_constant.g_type_img
        THEN
            g_error := 'CALL PK_IMAGE_TECH.SET_EXAM_GRID_TASK';
            IF NOT pk_image_tech.set_exam_grid_task(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_episode      => i_episode,
                                                    i_exam_req     => i_exam_req,
                                                    i_exam_req_det => i_exam_req_det,
                                                    i_flg_type     => pk_exam_constant.g_type_img,
                                                    o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSIF l_flg_type = pk_exam_constant.g_type_exm
        THEN
            g_error := 'CALL PK_EXAMS.SET_GRID_TASK_EXAMS';
            IF NOT pk_exams.set_exam_grid_task(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_episode      => i_episode,
                                               i_exam_req     => i_exam_req,
                                               i_exam_req_det => i_exam_req_det,
                                               i_flg_type     => pk_exam_constant.g_type_exm,
                                               o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'set_exam_grid_task',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_grid_task;

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
                   er.id_episode,
                   erd.flg_referral,
                   e.id_exam_cat,
                   e.flg_available,
                   er.id_prof_req,
                   er.dt_begin_tstz,
                   er.dt_req_tstz,
                   er.dt_schedule_tstz,
                   er.flg_time,
                   erd.flg_status,
                   decode(eres.id_exam_result, NULL, pk_exam_constant.g_no, pk_exam_constant.g_yes) flg_result,
                   er.flg_contact,
                   erd.id_task_dependency,
                   erd.flg_req_origin_module,
                   pk_announced_arrival.get_ann_arrival_id(i_prof.institution,
                                                           ei.id_software,
                                                           er.id_episode,
                                                           ei.flg_unknown,
                                                           aa.id_announced_arrival,
                                                           aa.flg_status) id_announced_arrival
              FROM exam e, exam_req er, exam_req_det erd, exam_result eres, announced_arrival aa, epis_info ei
             WHERE er.id_exam_req = erd.id_exam_req
               AND er.id_exam_req = i_exam_req
               AND erd.id_exam_req_det = i_exam_req_det
               AND erd.id_exam = e.id_exam
               AND e.flg_type = pk_exam_constant.g_type_exm
               AND eres.id_exam_req_det(+) = erd.id_exam_req_det
               AND eres.flg_status(+) != pk_exam_constant.g_exam_result_cancel
               AND (ei.id_episode = er.id_episode OR ei.id_episode = er.id_episode_origin)
               AND aa.id_episode(+) = er.id_episode
            UNION ALL
            SELECT erd.id_exam,
                   er.id_episode,
                   erd.flg_referral,
                   e.id_exam_cat,
                   e.flg_available,
                   er.id_prof_req,
                   er.dt_begin_tstz,
                   er.dt_req_tstz,
                   er.dt_schedule_tstz,
                   er.flg_time,
                   erd.flg_status,
                   pk_exam_constant.g_no     flg_result,
                   er.flg_contact,
                   erd.id_task_dependency,
                   erd.flg_req_origin_module,
                   NULL                      id_announced_arrival
              FROM exam e, exam_req er, exam_req_det erd
             WHERE er.id_exam_req = erd.id_exam_req
               AND er.id_exam_req = i_exam_req
               AND erd.id_exam_req_det = i_exam_req_det
               AND erd.id_exam = e.id_exam
               AND e.flg_type = pk_exam_constant.g_type_exm
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
            SELECT e.flg_status,
                   pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution) id_software,
                   e.id_epis_type,
                   e.id_clinical_service,
                   e.id_fast_track
              FROM episode e
             WHERE e.id_episode = i_episode
               AND e.flg_status != pk_alert_constant.g_epis_status_cancel;
    
        CURSOR c_epis_info(l_clinical_service IN NUMBER) IS
            SELECT ei.id_schedule,
                   cs.id_clinical_service,
                   d.id_dept,
                   pk_date_utils.date_send_tsz(i_lang, ei.dt_first_obs_tstz, i_prof) dt_first_obs_tstz
              FROM episode e, epis_info ei, clinical_service cs, dept d
             WHERE e.id_episode = i_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_dep_clin_serv IS NOT NULL
               AND cs.id_clinical_service = nvl(l_clinical_service, e.id_clinical_service)
               AND e.id_dept = d.id_dept
               AND d.id_institution = i_prof.institution
            UNION
            SELECT ei.id_schedule,
                   cs.id_clinical_service,
                   d.id_dept,
                   pk_date_utils.date_send_tsz(i_lang, ei.dt_first_obs_tstz, i_prof) dt_first_obs_tstz
              FROM episode e, epis_info ei, clinical_service cs, dept d
             WHERE e.id_episode = i_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_dep_clin_serv IS NULL
               AND cs.id_clinical_service = decode(l_clinical_service, -1, e.id_cs_requested, l_clinical_service)
               AND e.id_dept_requested = d.id_dept
               AND d.id_institution = i_prof.institution
            UNION
            SELECT ei.id_schedule,
                   NULL id_clinical_service,
                   d.id_dept,
                   pk_date_utils.date_send_tsz(i_lang, ei.dt_first_obs_tstz, i_prof) dt_first_obs_tstz
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
    
        l_clinical_service clinical_service.id_clinical_service%TYPE;
        l_flg_referral     exam_req_det.flg_referral%TYPE;
    
        l_grid_task_oth_exm grid_task_oth_exm%ROWTYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_exam_req_det IS NULL
           OR i_flg_type != pk_exam_constant.g_type_exm
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'PK_EXAMS.SET_EXAM_GRID_TASK / i_exam_req_det is null';
            RAISE g_other_exception;
        END IF;
    
        g_error := 'OPEN C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_grid_task_oth_exm.id_patient,
                 l_grid_task_oth_exm.gender,
                 l_grid_task_oth_exm.pat_age,
                 l_grid_task_oth_exm.num_clin_record;
        CLOSE c_patient;
    
        l_grid_task_oth_exm.id_episode := i_episode;
    
        g_error := 'OPEN C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_grid_task_oth_exm.flg_status_epis,
                 l_grid_task_oth_exm.id_software,
                 l_grid_task_oth_exm.id_epis_type,
                 l_clinical_service,
                 l_grid_task_oth_exm.id_fast_track;
        CLOSE c_episode;
    
        g_error := 'OPEN C_EPIS_INFO';
        OPEN c_epis_info(l_clinical_service);
        FETCH c_epis_info
            INTO l_grid_task_oth_exm.id_schedule,
                 l_grid_task_oth_exm.id_clinical_service,
                 l_grid_task_oth_exm.id_dept,
                 l_grid_task_oth_exm.dt_first_obs;
        CLOSE c_epis_info;
    
        g_error := 'OPEN C_TRIAGE_COLOR';
        OPEN c_triage_color;
        FETCH c_triage_color
            INTO l_grid_task_oth_exm.acuity,
                 l_grid_task_oth_exm.rank_acuity,
                 l_grid_task_oth_exm.color,
                 l_grid_task_oth_exm.id_triage_color;
        CLOSE c_triage_color;
    
        g_error := 'OPEN C_EXAM_REQ';
        OPEN c_exam_req;
        FETCH c_exam_req
            INTO l_grid_task_oth_exm.id_exam,
                 l_grid_task_oth_exm.id_episode,
                 l_flg_referral,
                 l_grid_task_oth_exm.id_exam_cat,
                 l_grid_task_oth_exm.flg_available,
                 l_grid_task_oth_exm.id_professional,
                 l_grid_task_oth_exm.dt_begin_tstz,
                 l_grid_task_oth_exm.dt_req_tstz,
                 l_grid_task_oth_exm.dt_schedule_tstz,
                 l_grid_task_oth_exm.flg_time,
                 l_grid_task_oth_exm.flg_status_req_det,
                 l_grid_task_oth_exm.flg_result,
                 l_grid_task_oth_exm.flg_contact,
                 l_grid_task_oth_exm.id_task_dependency,
                 l_grid_task_oth_exm.flg_req_origin_module,
                 l_grid_task_oth_exm.id_announced_arrival;
        g_found := c_exam_req%FOUND;
        CLOSE c_exam_req;
    
        l_grid_task_oth_exm.nick_name := pk_prof_utils.get_nickname(i_lang, l_grid_task_oth_exm.id_professional);
    
        IF NOT g_found
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_EXAMS.SET_EXAM_GRID_TASK / ' ||
                       g_error;
            RAISE g_other_exception;
        END IF;
    
        g_error := 'MERGE INTO GRID_TASK_OTH_EXM';
        MERGE INTO grid_task_oth_exm gtoe
        USING (SELECT i_exam_req id_exam_req,
                      i_exam_req_det id_exam_req_det,
                      l_grid_task_oth_exm.id_professional id_professional,
                      l_grid_task_oth_exm.gender gender,
                      l_grid_task_oth_exm.id_patient id_patient,
                      l_grid_task_oth_exm.id_episode id_episode,
                      decode(l_grid_task_oth_exm.id_episode, NULL, NULL, l_grid_task_oth_exm.flg_status_epis) flg_status_epis,
                      l_grid_task_oth_exm.id_clinical_service id_clinical_service,
                      l_grid_task_oth_exm.id_dept id_dept,
                      l_grid_task_oth_exm.id_schedule id_schedule,
                      l_grid_task_oth_exm.dt_first_obs dt_first_obs,
                      l_grid_task_oth_exm.rank rank,
                      l_grid_task_oth_exm.num_clin_record num_clin_record,
                      l_grid_task_oth_exm.nick_name nick_name,
                      l_grid_task_oth_exm.dt_begin_tstz dt_begin_tstz,
                      l_grid_task_oth_exm.dt_req_tstz dt_req_tstz,
                      l_grid_task_oth_exm.dt_schedule_tstz dt_schedule_tstz,
                      l_grid_task_oth_exm.id_exam id_exam,
                      l_grid_task_oth_exm.flg_status_req_det flg_status_req_det,
                      l_grid_task_oth_exm.flg_time flg_time,
                      l_grid_task_oth_exm.id_exam_cat id_exam_cat,
                      l_grid_task_oth_exm.flg_available flg_available,
                      l_grid_task_oth_exm.acuity acuity,
                      l_grid_task_oth_exm.rank_acuity rank_acuity,
                      l_grid_task_oth_exm.color color,
                      l_grid_task_oth_exm.id_triage_color id_triage_color,
                      l_grid_task_oth_exm.id_fast_track id_fast_track,
                      l_grid_task_oth_exm.pat_age pat_age,
                      l_grid_task_oth_exm.flg_result flg_result,
                      decode(l_grid_task_oth_exm.id_episode, NULL, NULL, l_grid_task_oth_exm.id_epis_type) id_epis_type,
                      nvl(l_grid_task_oth_exm.id_institution, i_prof.institution) id_institution,
                      nvl(l_grid_task_oth_exm.id_software, i_prof.software) id_software,
                      pk_exam_constant.g_type_exm flg_type,
                      l_grid_task_oth_exm.flg_contact flg_contact,
                      l_grid_task_oth_exm.id_task_dependency id_task_dependency,
                      l_grid_task_oth_exm.flg_req_origin_module flg_req_origin_module,
                      l_grid_task_oth_exm.id_announced_arrival id_announced_arrival
                 FROM dual) rec
        ON (gtoe.id_exam_req = rec.id_exam_req AND gtoe.id_exam_req_det = rec.id_exam_req_det)
        WHEN MATCHED THEN
            UPDATE
               SET id_professional       = rec.id_professional,
                   gender                = rec.gender,
                   id_patient            = rec.id_patient,
                   id_episode            = rec.id_episode,
                   flg_status_epis       = rec.flg_status_epis,
                   id_clinical_service   = rec.id_clinical_service,
                   id_dept               = nvl(rec.id_dept, gtoe.id_dept),
                   id_schedule           = rec.id_schedule,
                   dt_first_obs          = rec.dt_first_obs,
                   rank                  = rec.rank,
                   num_clin_record       = rec.num_clin_record,
                   nick_name             = rec.nick_name,
                   dt_begin_tstz         = rec.dt_begin_tstz,
                   dt_req_tstz           = rec.dt_req_tstz,
                   dt_schedule_tstz      = rec.dt_schedule_tstz,
                   id_exam               = rec.id_exam,
                   flg_status_req_det    = rec.flg_status_req_det,
                   flg_time              = rec.flg_time,
                   id_exam_cat           = rec.id_exam_cat,
                   flg_available         = rec.flg_available,
                   acuity                = rec.acuity,
                   rank_acuity           = rec.rank_acuity,
                   color                 = rec.color,
                   id_triage_color       = rec.id_triage_color,
                   id_fast_track         = rec.id_fast_track,
                   pat_age               = rec.pat_age,
                   flg_result            = rec.flg_result,
                   id_epis_type          = rec.id_epis_type,
                   id_institution        = rec.id_institution,
                   id_software           = rec.id_software,
                   flg_contact           = rec.flg_contact,
                   id_task_dependency    = rec.id_task_dependency,
                   flg_req_origin_module = rec.flg_req_origin_module,
                   id_announced_arrival  = rec.id_announced_arrival
        WHEN NOT MATCHED THEN
            INSERT
                (id_exam_req,
                 id_exam_req_det,
                 id_professional,
                 gender,
                 id_patient,
                 id_episode,
                 flg_status_epis,
                 id_clinical_service,
                 id_dept,
                 id_schedule,
                 dt_first_obs,
                 rank,
                 num_clin_record,
                 nick_name,
                 dt_begin_tstz,
                 dt_req_tstz,
                 dt_schedule_tstz,
                 id_exam,
                 flg_time,
                 flg_status_req_det,
                 id_exam_cat,
                 flg_available,
                 acuity,
                 rank_acuity,
                 color,
                 id_triage_color,
                 id_fast_track,
                 pat_age,
                 flg_result,
                 id_epis_type,
                 id_institution,
                 id_software,
                 flg_type,
                 flg_contact,
                 id_task_dependency,
                 flg_req_origin_module,
                 id_announced_arrival)
            VALUES
                (rec.id_exam_req,
                 rec.id_exam_req_det,
                 rec.id_professional,
                 rec.gender,
                 rec.id_patient,
                 rec.id_episode,
                 rec.flg_status_epis,
                 rec.id_clinical_service,
                 rec.id_dept,
                 rec.id_schedule,
                 rec.dt_first_obs,
                 rec.rank,
                 rec.num_clin_record,
                 rec.nick_name,
                 rec.dt_begin_tstz,
                 rec.dt_req_tstz,
                 rec.dt_schedule_tstz,
                 rec.id_exam,
                 rec.flg_time,
                 rec.flg_status_req_det,
                 rec.id_exam_cat,
                 rec.flg_available,
                 rec.acuity,
                 rec.rank_acuity,
                 rec.color,
                 rec.id_triage_color,
                 rec.id_fast_track,
                 rec.pat_age,
                 rec.flg_result,
                 rec.id_epis_type,
                 rec.id_institution,
                 rec.id_software,
                 rec.flg_type,
                 rec.flg_contact,
                 rec.id_task_dependency,
                 rec.flg_req_origin_module,
                 rec.id_announced_arrival);
    
        DELETE grid_task_oth_exm gtoe
         WHERE gtoe.id_exam_req_det = i_exam_req_det
           AND l_grid_task_oth_exm.id_epis_type != pk_exam_constant.g_episode_type_exm
           AND ((gtoe.flg_status_req_det IN (pk_exam_constant.g_exam_predefined,
                                             pk_exam_constant.g_exam_draft,
                                             pk_exam_constant.g_exam_exterior,
                                             pk_exam_constant.g_exam_read,
                                             pk_exam_constant.g_exam_cancel)) OR
               (gtoe.flg_status_req_det = pk_exam_constant.g_exam_result AND
               gtoe.flg_status_epis = pk_alert_constant.g_epis_status_pendent) OR
               (l_flg_referral IN (pk_exam_constant.g_flg_referral_r,
                                    pk_exam_constant.g_flg_referral_s,
                                    pk_exam_constant.g_flg_referral_i)));
    
        IF l_grid_task_oth_exm.id_epis_type != pk_exam_constant.g_episode_type_exm
           AND l_grid_task_oth_exm.flg_status_epis = pk_alert_constant.g_epis_status_inactive
        THEN
            DELETE grid_task_oth_exm gtoe
             WHERE gtoe.id_episode = l_grid_task_oth_exm.id_episode;
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
            RETURN FALSE;
    END set_exam_grid_task;

    FUNCTION set_technician_grid_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN exam_req.id_patient%TYPE,
        i_episode        IN exam_req.id_episode%TYPE,
        i_exam_req       IN exam_req.id_exam_req%TYPE,
        i_flg_contact    IN exam_req.flg_contact%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exam_req_det IS
            SELECT erd.id_exam_req_det
              FROM exam_req_det erd
             WHERE erd.id_exam_req = i_exam_req;
    
        CURSOR c_exam_req IS
            SELECT 'X'
              FROM exam_req er
             WHERE er.id_episode = (SELECT id_episode
                                      FROM exam_req
                                     WHERE id_exam_req = i_exam_req)
               AND er.flg_status IN (pk_exam_constant.g_exam_req,
                                     pk_exam_constant.g_exam_pending,
                                     pk_exam_constant.g_exam_toexec,
                                     pk_exam_constant.g_exam_transp,
                                     pk_exam_constant.g_exam_end_transp);
    
        l_exam_req       VARCHAR2(1);
        l_schedule       epis_info.id_schedule%TYPE;
        l_transaction_id VARCHAR2(4000);
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF pk_sysconfig.get_config('EXAMS_WORKFLOW', i_prof) = pk_exam_constant.g_yes
        THEN
            IF i_flg_contact = pk_exam_constant.g_in_technician
            THEN
                g_error := 'UPDATE EXAM_REQ';
                ts_exam_req.upd(id_exam_req_in => i_exam_req,
                                flg_contact_in => i_flg_contact,
                                dt_contact_in  => g_sysdate_tstz,
                                rows_out       => l_rows_out);
            
                BEGIN
                    SELECT e.id_schedule
                      INTO l_schedule
                      FROM exam_req er, epis_info e
                     WHERE er.id_exam_req = i_exam_req
                       AND er.id_episode = e.id_episode
                       AND er.flg_contact IN (pk_exam_constant.g_waiting_technician, pk_exam_constant.g_in_technician);
                
                    g_error := 'UPDATE SCHEDULE_OUTP';
                    IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                               i_prof           => i_prof,
                                                                               i_id_schedule    => l_schedule,
                                                                               i_flg_state      => i_flg_contact,
                                                                               i_id_patient     => i_patient,
                                                                               i_transaction_id => l_transaction_id,
                                                                               o_error          => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_schedule := NULL;
                END;
            
            ELSIF i_flg_contact IN
                  (pk_exam_constant.g_exam_cancel, pk_exam_constant.g_exam_nr, pk_exam_constant.g_end_technician)
            THEN
                OPEN c_exam_req;
                FETCH c_exam_req
                    INTO l_exam_req;
                g_found := c_exam_req%NOTFOUND;
                CLOSE c_exam_req;
            
                IF g_found
                THEN
                    g_error := 'UPDATE EXAM_REQ';
                    ts_exam_req.upd(id_exam_req_in => i_exam_req,
                                    flg_contact_in => i_flg_contact,
                                    rows_out       => l_rows_out);
                
                    BEGIN
                        SELECT e.id_schedule
                          INTO l_schedule
                          FROM exam_req er, epis_info e
                         WHERE er.id_exam_req = i_exam_req
                           AND er.id_episode = e.id_episode
                           AND er.flg_contact IN
                               (pk_exam_constant.g_waiting_technician, pk_exam_constant.g_in_technician);
                    
                        g_error := 'UPDATE SCHEDULE_OUTP';
                        IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                                   i_prof           => i_prof,
                                                                                   i_id_schedule    => l_schedule,
                                                                                   i_flg_state      => pk_exam_constant.g_end_technician,
                                                                                   i_id_patient     => i_patient,
                                                                                   i_transaction_id => l_transaction_id,
                                                                                   o_error          => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                ELSE
                    IF i_flg_contact = pk_exam_constant.g_end_technician
                    THEN
                        g_error := 'UPDATE EXAM_REQ';
                        ts_exam_req.upd(id_exam_req_in => i_exam_req,
                                        flg_contact_in => i_flg_contact,
                                        rows_out       => l_rows_out);
                    
                        BEGIN
                            SELECT e.id_schedule
                              INTO l_schedule
                              FROM exam_req er, epis_info e
                             WHERE er.id_exam_req = i_exam_req
                               AND er.id_episode = e.id_episode
                               AND er.flg_contact IN
                                   (pk_exam_constant.g_waiting_technician, pk_exam_constant.g_in_technician);
                        
                            g_error := 'UPDATE SCHEDULE_OUTP';
                            IF NOT pk_schedule_api_upstream.set_schedule_consult_state(i_lang           => i_lang,
                                                                                       i_prof           => i_prof,
                                                                                       i_id_schedule    => l_schedule,
                                                                                       i_flg_state      => i_flg_contact,
                                                                                       i_id_patient     => i_patient,
                                                                                       i_transaction_id => l_transaction_id,
                                                                                       o_error          => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        EXCEPTION
                            WHEN no_data_found THEN
                                NULL;
                        END;
                    ELSE
                        g_error := 'UPDATE EXAM_REQ';
                        ts_exam_req.upd(id_exam_req_in => i_exam_req,
                                        flg_contact_in => i_flg_contact,
                                        rows_out       => l_rows_out);
                    END IF;
                END IF;
            ELSE
                g_error := 'UPDATE EXAM_REQ';
                ts_exam_req.upd(id_exam_req_in => i_exam_req, flg_contact_in => i_flg_contact, rows_out => l_rows_out);
            END IF;
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EXAM_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            FOR rec IN c_exam_req_det
            LOOP
                g_error := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
                IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_patient      => i_patient,
                                                          i_episode      => i_episode,
                                                          i_exam_req     => i_exam_req,
                                                          i_exam_req_det => rec.id_exam_req_det,
                                                          o_error        => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        END IF;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'SET_TECHNICIAN_GRID_STATUS',
                                              o_error);
            --remote scheduler rollback doesn't affect PFH database
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_technician_grid_status;

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
             gtoe.id_exam_req, gtoe.id_exam_req_det, e.flg_status
              FROM grid_task_oth_exm gtoe
              JOIN episode e
                ON e.id_episode = gtoe.id_episode
             WHERE e.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                column_value
                                 FROM TABLE(i_rowids) t);
    
    BEGIN
    
        g_error := 'VALIDATE ARGUEMTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'EPISODE',
                                                 i_expected_dg_table_name => 'GRID_TASK_OTH_EXM',
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
                
                    UPDATE grid_task_oth_exm gtoe
                       SET gtoe.flg_status_epis = l_flg_status
                     WHERE gtoe.id_exam_req = l_id_exam_req
                       AND gtoe.id_exam_req_det = l_id_exam_req_det;
                END LOOP;
                CLOSE c_grid_task;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_exam_episode_status;

    FUNCTION get_technician_grid_view
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT id_action, NULL id_parent, desc_action, NULL icon, 'A' flg_action
              FROM (SELECT sd.val id_action, sd.desc_val desc_action, sd.rank
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'TECHNICIAN_GRID_VIEW', NULL)) sd,
                           software_institution si
                     WHERE sd.val != g_exam_req_all
                       AND sd.val = si.id_software
                       AND si.id_institution = i_prof.institution
                    UNION ALL
                    SELECT sd.val id_action, sd.desc_val desc_action, sd.rank
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'TECHNICIAN_GRID_VIEW', NULL)) sd
                     WHERE sd.val = g_exam_req_all)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TECHNICIAN_GRID_VIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_technician_grid_view;

    FUNCTION get_technician_grid_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_exam_req IN exam_req.id_exam_req%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_schedule      schedule_outp.id_schedule%TYPE;
        l_episode_state schedule_outp.flg_state%TYPE;
        l_exam_state    exam_req.flg_contact%TYPE;
    
    BEGIN
    
        SELECT er.flg_contact
          INTO l_exam_state
          FROM exam_req er
         WHERE er.id_exam_req = i_exam_req;
    
        BEGIN
            SELECT id_schedule, flg_state
              INTO l_schedule, l_episode_state
              FROM schedule_outp
             WHERE id_schedule = (SELECT e.id_schedule
                                    FROM exam_req er, epis_info e
                                   WHERE er.id_exam_req = i_exam_req
                                     AND er.id_episode = e.id_episode);
        EXCEPTION
            WHEN no_data_found THEN
                l_schedule      := -1;
                l_episode_state := l_exam_state;
        END;
    
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT val data,
                   desc_val label,
                   rank,
                   img_name icon,
                   decode(l_schedule,
                           -1,
                           CASE
                               WHEN val IN (pk_exam_constant.g_exam_sched,
                                            pk_exam_constant.g_exam_efectiv,
                                            pk_exam_constant.g_waiting_technician) THEN
                                pk_exam_constant.g_no
                               WHEN val = pk_exam_constant.g_in_technician THEN
                                decode(l_exam_state,
                                       pk_exam_constant.g_waiting_technician,
                                       pk_exam_constant.g_yes,
                                       pk_exam_constant.g_no)
                               WHEN val = pk_exam_constant.g_end_technician THEN
                                decode(l_exam_state,
                                       pk_exam_constant.g_in_technician,
                                       pk_exam_constant.g_yes,
                                       pk_exam_constant.g_no)
                               ELSE
                                pk_exam_constant.g_no
                           END,
                           CASE
                               WHEN l_episode_state IN (pk_exam_constant.g_waiting_technician,
                                                        pk_exam_constant.g_in_technician,
                                                        pk_exam_constant.g_end_technician) THEN
                                CASE
                                    WHEN val IN (pk_exam_constant.g_exam_sched,
                                                 pk_exam_constant.g_exam_efectiv,
                                                 pk_exam_constant.g_waiting_technician) THEN
                                     pk_exam_constant.g_no
                                    WHEN val = pk_exam_constant.g_in_technician THEN
                                     decode(l_exam_state,
                                            pk_exam_constant.g_waiting_technician,
                                            pk_exam_constant.g_yes,
                                            pk_exam_constant.g_no)
                                    WHEN val = pk_exam_constant.g_end_technician THEN
                                     decode(l_exam_state,
                                            pk_exam_constant.g_in_technician,
                                            pk_exam_constant.g_yes,
                                            pk_exam_constant.g_no)
                                    ELSE
                                     pk_exam_constant.g_no
                                END
                               ELSE
                                pk_exam_constant.g_no
                           END) flg_action
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'EXAM_REQ.FLG_CONTACT', NULL)) s
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TECHNICIAN_GRID_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_technician_grid_list;

    FUNCTION get_technician_grid
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_filter IN VARCHAR2,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_today TIMESTAMP WITH LOCAL TIME ZONE;
        l_date1 TIMESTAMP WITH LOCAL TIME ZONE;
        l_date2 TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_msg_order sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAMS_T239');
        l_msg_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAMS_T007');
    
        l_num_days_back sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK',
                                                                         i_prof);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_today := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
    
        DELETE grid_task_oth_exm gtoe
         WHERE gtoe.flg_status_req_det = pk_exam_constant.g_exam_result
           AND gtoe.dt_req_tstz <= l_today - INTERVAL '1'
         DAY
           AND gtoe.id_epis_type != pk_exam_constant.g_episode_type_exm;
    
        DELETE grid_task_oth_exm gtoe
         WHERE gtoe.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtoe.id_epis_type != pk_exam_constant.g_episode_type_exm;
    
        l_num_days_back := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
    
        l_date1 := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_date2 := l_date1 + INTERVAL '1' DAY;
    
        DELETE grid_task_oth_exm gtoe
         WHERE gtoe.flg_status_req_det IN
               (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
           AND gtoe.dt_begin_tstz BETWEEN l_date1 AND l_date2
           AND gtoe.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtoe.id_epis_type = pk_exam_constant.g_episode_type_exm;
    
        COMMIT;
    
        l_date1 := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) - INTERVAL '4' hour;
    
        l_date2 := l_date1 + INTERVAL '28' hour;
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT id_patient,
                   id_episode,
                   id_exam_req,
                   acuity,
                   rank_acuity,
                   (SELECT pk_fast_track.get_fast_track_icon(i_lang,
                                                             i_prof,
                                                             id_episode,
                                                             id_fast_track,
                                                             id_triage_color,
                                                             NULL,
                                                             NULL)
                      FROM dual) fast_track_icon,
                   decode(acuity,
                          pk_alert_constant.g_ft_color,
                          pk_alert_constant.g_ft_triage_white,
                          pk_alert_constant.g_ft_color) fast_track_color,
                   pk_alert_constant.g_ft_status fast_track_status,
                   (SELECT pk_fast_track.get_fast_track_desc(i_lang, i_prof, id_fast_track, 'G')
                      FROM dual) fast_track_desc,
                   dt_first_obs,
                   id_schedule,
                   id_epis_type,
                   (SELECT pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.' || id_software)
                      FROM dual) epis_type,
                   (SELECT pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || id_institution)
                      FROM dual) desc_institution,
                   (SELECT pk_patient.get_pat_name(i_lang, i_prof, id_patient, id_episode, NULL)
                      FROM dual) name,
                   (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, id_patient)
                      FROM dual) pat_ndo,
                   (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, id_patient)
                      FROM dual) pat_nd_icon,
                   (SELECT pk_patient.get_gender(i_lang, gender)
                      FROM dual) gender,
                   pat_age,
                   (SELECT pk_patphoto.get_pat_photo(i_lang, i_prof, id_patient, id_episode, id_schedule)
                      FROM dual) photo,
                   num_clin_record,
                   nick_name,
                   (SELECT pk_date_utils.date_char_hour_tsz(i_lang, dt_begin_tstz, i_prof.institution, i_prof.software)
                      FROM dual) dt_target,
                   l_msg_order || id_exam_req desc_order,
                   id_exam,
                   decode(flg_type,
                          'E',
                          (SELECT pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || id_exam)
                             FROM dual),
                          (SELECT pk_translation.get_translation(i_lang, 'EXAM_GROUP.CODE_EXAM_GROUP.' || id_exam)
                             FROM dual)) desc_exam,
                   id_task_dependency,
                   (SELECT pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_REQ_ORIGIN_MODULE', flg_req_origin_module)
                      FROM dual) icon_name,
                   decode(flg_notes, pk_exam_constant.g_yes, l_msg_notes, NULL) msg_notes,
                   flg_status,
                   (SELECT pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || id_dept)
                      FROM dual) || decode(id_clinical_service,
                                           NULL,
                                           NULL,
                                           ' - ' || (SELECT pk_translation.get_translation(i_lang,
                                                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                                                           id_clinical_service)
                                                       FROM dual)) dept,
                   (SELECT pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.PRIORITY', priority, NULL)
                      FROM dual) priority,
                   (SELECT pk_utils.get_status_string(i_lang,
                                                      i_prof,
                                                      status_str_req,
                                                      status_msg_req,
                                                      status_icon_req,
                                                      status_flg_req)
                      FROM dual) status_string,
                   decode(flg_status,
                          pk_exam_constant.g_exam_cancel,
                          (SELECT pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_CONTACT', flg_contact)
                             FROM dual),
                          decode(nvl(id_schedule, -1),
                                 -1,
                                 (SELECT pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_CONTACT', flg_contact)
                                    FROM dual),
                                 (SELECT pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_STATE', flg_state)
                                    FROM dual))) contact_state,
                   decode(flg_status,
                          pk_exam_constant.g_exam_cancel,
                          pk_exam_constant.g_no,
                          pk_exam_constant.g_exam_exec,
                          pk_exam_constant.g_no,
                          pk_exam_constant.g_exam_result,
                          pk_exam_constant.g_no,
                          pk_exam_constant.g_exam_read,
                          pk_exam_constant.g_no,
                          pk_exam_constant.g_yes) avail_button_cancel,
                   decode(flg_type, 'E', 11, decode(flg_contact, pk_exam_constant.g_waiting_technician, 1794, 11)) id_shortcut,
                   (SELECT pk_patient.get_pat_name_to_sort(i_lang, i_prof, id_patient, id_episode, NULL)
                      FROM dual) order_name,
                   decode(flg_status,
                          pk_exam_constant.g_exam_req,
                          row_number()
                          over(ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, 'EXAM_REQ.FLG_STATUS', flg_status)
                                  FROM dual),
                               coalesce(dt_pend_req, dt_begin, dt_req)),
                          pk_exam_constant.g_exam_pending,
                          row_number()
                          over(ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, 'EXAM_REQ.FLG_STATUS', flg_status)
                                  FROM dual),
                               coalesce(dt_pend_req, dt_begin, dt_req)),
                          row_number()
                          over(ORDER BY (SELECT pk_sysdomain.get_rank(i_lang, 'EXAM_REQ.FLG_STATUS', flg_status)
                                  FROM dual),
                               coalesce(dt_pend_req, dt_begin, dt_req) DESC)) rank_ord,
                   (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(dt_pend_req, nvl(dt_begin, dt_req)), i_prof)
                      FROM dual) dt_ord
              FROM (SELECT DISTINCT gtoe.rank,
                                    gtoe.acuity,
                                    gtoe.rank_acuity,
                                    gtoe.id_triage_color,
                                    gtoe.id_fast_track,
                                    gtoe.id_software,
                                    gtoe.id_institution,
                                    gtoe.dt_first_obs,
                                    gtoe.id_schedule,
                                    gtoe.id_episode,
                                    gtoe.id_epis_type,
                                    gtoe.id_patient,
                                    gtoe.gender,
                                    gtoe.pat_age,
                                    gtoe.num_clin_record,
                                    gtoe.nick_name,
                                    gtoe.dt_begin_tstz,
                                    gtoe.id_exam_req,
                                    gtoe.id_dept,
                                    gtoe.id_clinical_service,
                                    gtoe.flg_contact,
                                    decode(eea.id_exam_group, NULL, eea.id_exam, eea.id_exam_group) id_exam,
                                    decode(eea.id_exam_group, NULL, 'E', 'G') flg_type,
                                    eea.flg_time,
                                    eea.dt_req,
                                    eea.dt_begin,
                                    eea.dt_pend_req,
                                    eea.priority,
                                    eea.flg_notes,
                                    eea.flg_status_req flg_status,
                                    eea.status_str_req,
                                    eea.status_msg_req,
                                    eea.status_icon_req,
                                    eea.status_flg_req,
                                    so.flg_state,
                                    gtoe.id_task_dependency,
                                    gtoe.flg_req_origin_module
                      FROM grid_task_oth_exm gtoe, exams_ea eea, exam_cat_dcs ecdcs, schedule_outp so
                     WHERE (to_number(nvl(i_filter, 0)) = 0 OR gtoe.id_software = to_number(i_filter))
                       AND (EXISTS
                            (SELECT 1
                               FROM institution i
                              WHERE i.id_parent = (SELECT i.id_parent
                                                     FROM institution i
                                                    WHERE i.id_institution = i_prof.institution)
                                AND i.id_institution = gtoe.id_institution) OR gtoe.id_institution = i_prof.institution)
                       AND ((gtoe.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d) AND
                           gtoe.dt_begin_tstz BETWEEN l_date1 AND l_date2 AND
                           gtoe.flg_status_req_det NOT IN
                           (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched)) OR
                           (gtoe.flg_time = pk_exam_constant.g_flg_time_e AND
                           pk_date_utils.trunc_insttimezone(i_prof, gtoe.dt_begin_tstz) <= l_today AND
                           gtoe.flg_status_epis NOT IN (pk_alert_constant.g_inactive, pk_alert_constant.g_cancelled)) OR
                           (gtoe.flg_time = pk_exam_constant.g_flg_time_n AND gtoe.id_episode IS NOT NULL AND
                           gtoe.flg_status_req_det != pk_exam_constant.g_exam_pending))
                       AND gtoe.id_exam_req_det = eea.id_exam_req_det
                       AND gtoe.id_exam_cat = ecdcs.id_exam_cat
                       AND gtoe.flg_status_req_det NOT IN
                           (pk_exam_constant.g_exam_exterior,
                            pk_exam_constant.g_exam_wtg_tde,
                            pk_exam_constant.g_exam_cancel)
                       AND EXISTS (SELECT 1
                              FROM prof_dep_clin_serv pdcs
                             WHERE pdcs.id_professional = i_prof.id
                               AND pdcs.flg_status = pk_exam_constant.g_selected
                               AND pdcs.id_institution = gtoe.id_institution
                               AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv)
                       AND instr(nvl((SELECT flg_first_result
                                       FROM exam_dep_clin_serv e
                                      WHERE e.id_exam = gtoe.id_exam
                                        AND e.flg_type = pk_exam_constant.g_exam_can_req
                                        AND e.id_software = gtoe.id_software
                                        AND e.id_institution = gtoe.id_institution),
                                     '#'),
                                 pk_alert_constant.g_cat_type_technician) != 0
                       AND gtoe.id_schedule = so.id_schedule(+)
                       AND gtoe.id_announced_arrival IS NOT NULL)
             ORDER BY rank_ord;
    
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
            RETURN FALSE;
    END get_technician_grid;

    FUNCTION check_technician_contact
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exam_req  IN exam_req.id_exam_req%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_contact exam_req.dt_contact%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT er.dt_contact
              INTO l_dt_contact
              FROM exam_req er
             WHERE er.id_exam_req = i_exam_req;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_contact := NULL;
        END;
    
        IF l_dt_contact IS NOT NULL
        THEN
            o_flg_show := pk_exam_constant.g_no;
        ELSE
            o_flg_show  := pk_exam_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'EXAMS_M002');
            o_msg       := pk_message.get_message(i_lang, i_prof, 'EXAMS_M003');
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
                                              'CHECK_TECHNICIAN_CONTACT',
                                              o_error);
            RETURN FALSE;
        
    END check_technician_contact;

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
            SELECT gtoe.id_exam_req,
                   gtoe.id_exam_req_det,
                   gtoe.id_exam,
                   gtoe.flg_status_req_det flg_status,
                   (SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || gtoe.id_exam, NULL)
                      FROM dual) desc_exam,
                   decode(eea.notes_scheduler, NULL, pk_exam_constant.g_no, pk_exam_constant.g_yes) flg_notes,
                   (SELECT pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.' || gtoe.id_software)
                      FROM dual) epis_type,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'AB_INSTITUTION.CODE_INSTITUTION.' || gtoe.id_institution)
                      FROM dual) desc_institution,
                   l_msg_order || ' ' || gtoe.id_exam_req num_order,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eea.id_prof_req) prof_name,
                   pk_prof_utils.get_prof_speciality(i_lang,
                                                     profissional(eea.id_prof_req, gtoe.id_software, gtoe.id_institution)) desc_speciality,
                   decode(gtoe.flg_status_req_det,
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
                   pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', gtoe.flg_status_req_det) rank,
                   pk_date_utils.date_send_tsz(i_lang, nvl(eea.dt_begin, eea.dt_req), i_prof) dt_ord,
                   eea.id_patient,
                   eea.id_prof_req,
                   pk_exam_utils.get_exam_id_content(i_lang, i_prof, eea.id_exam) id_content
              FROM grid_task_oth_exm gtoe
              JOIN exams_ea eea
                ON eea.id_exam_req_det = gtoe.id_exam_req_det
             WHERE gtoe.id_patient = i_patient
               AND gtoe.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
               AND gtoe.flg_status_req_det IN (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched)
               AND (EXISTS
                    (SELECT 1
                       FROM institution i
                      WHERE i.id_parent = (SELECT i.id_parent
                                             FROM institution i
                                            WHERE i.id_institution = i_prof.institution)
                        AND i.id_institution = gtoe.id_institution) OR gtoe.id_institution = i_prof.institution OR
                    (gtoe.id_institution != i_prof.institution AND EXISTS
                     (SELECT 1
                        FROM transfer_institution ti
                       WHERE ti.flg_status = pk_alert_constant.g_flg_status_f
                         AND ti.id_episode = gtoe.id_episode
                         AND ti.id_institution_dest = i_prof.institution)))
               AND EXISTS
             (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = pk_exam_constant.g_selected
                       AND pdcs.id_institution = gtoe.id_institution
                       AND pdcs.id_dep_clin_serv IN (SELECT ecd.id_dep_clin_serv
                                                       FROM alert.exam_cat_dcs ecd
                                                      WHERE ecd.id_exam_cat = gtoe.id_exam_cat))
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

    FUNCTION get_exam_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN exam_req.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cat IS
            SELECT cat.flg_type
              FROM category cat, prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND cat.id_category = pc.id_category;
    
        CURSOR c_epis IS
            SELECT e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_cat       category.flg_type%TYPE;
        l_epis_type epis_type.id_epis_type%TYPE;
    
        l_msg_notes     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAMS_T007');
        l_msg_exam_type sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAMS_T005');
        l_msg_exam      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAMS_T011');
    
    BEGIN
        g_error := 'OPEN C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        g_error := 'GET C_EPIS';
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis_type;
        CLOSE c_epis;
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT decode(eea.id_exam_group,
                          NULL,
                          NULL,
                          (SELECT eg.id_group_parent
                             FROM exam_group eg
                            WHERE eg.id_exam_group = eea.id_exam_group)) id_exam_type,
                   decode(eea.id_exam_group,
                          NULL,
                          l_msg_exam_type,
                          (SELECT pk_translation.get_translation(i_lang,
                                                                 'EXAM_GROUP.CODE_EXAM_GROUP.' || eg.id_group_parent)
                             FROM exam_group eg
                            WHERE eg.id_exam_group = eea.id_exam_group)) exam_type,
                   eea.id_exam_req,
                   eea.id_exam_req_det,
                   decode(eea.id_exam_group,
                          NULL,
                          l_msg_exam,
                          pk_translation.get_translation(i_lang, 'EXAM_GROUP.CODE_EXAM_GROUP.' || eea.id_exam_group)) exam_group,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) ||
                   decode(l_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     ep.id_epis_type,
                                                     eea.flg_status_req,
                                                     eea.id_exam_req,
                                                     pk_exam_constant.g_exam_type_req),
                              ep.id_epis_type),
                          '',
                          ' - (' || pk_message.get_message(i_lang,
                                                           profissional(i_prof.id,
                                                                        i_prof.institution,
                                                                        t_ti_log.get_epis_type_soft(i_lang,
                                                                                                    i_prof,
                                                                                                    ep.id_epis_type,
                                                                                                    eea.flg_status_req,
                                                                                                    eea.id_exam_req,
                                                                                                    pk_exam_constant.g_exam_type_req)),
                                                           'IMAGE_T009') || ')') desc_exam,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.PRIORITY', eea.priority, NULL) priority,
                   decode(eea.flg_notes, pk_exam_constant.g_no, '', l_msg_notes) msg_notes,
                   eea.flg_status_det flg_status,
                   pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              eea.status_str,
                                              eea.status_msg,
                                              eea.status_icon,
                                              eea.status_flg) status_string,
                   decode(l_cat,
                          g_technician,
                          decode(eea.flg_type,
                                 pk_exam_constant.g_type_img,
                                 pk_exam_constant.g_no,
                                 decode(instr(nvl(edcs.flg_first_result, '#'), l_cat),
                                        0,
                                        pk_exam_constant.g_no,
                                        decode(eea.flg_status_det,
                                               pk_exam_constant.g_exam_exterior,
                                               pk_exam_constant.g_no,
                                               pk_exam_constant.g_exam_cancel,
                                               pk_exam_constant.g_no,
                                               decode(eea.dt_begin, NULL, pk_exam_constant.g_no, pk_exam_constant.g_yes)))),
                          pk_exam_constant.g_yes) avail_button_ok,
                   decode(eea.flg_type,
                          pk_exam_constant.g_type_img,
                          pk_exam_constant.g_no,
                          decode(eea.flg_time,
                                 pk_exam_constant.g_flg_time_n,
                                 pk_exam_constant.g_no,
                                 decode(eea.flg_status_det,
                                        pk_exam_constant.g_exam_sched,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_exam_pending,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_exam_req,
                                        pk_exam_constant.g_yes,
                                        pk_exam_constant.g_no))) avail_button_action,
                   decode(eea.flg_type,
                          pk_exam_constant.g_type_img,
                          pk_exam_constant.g_no,
                          decode(eea.flg_status_det,
                                 pk_exam_constant.g_exam_cancel,
                                 pk_exam_constant.g_no,
                                 pk_exam_constant.g_exam_exec,
                                 pk_exam_constant.g_no,
                                 pk_exam_constant.g_exam_result,
                                 pk_exam_constant.g_no,
                                 pk_exam_constant.g_exam_read,
                                 pk_exam_constant.g_no,
                                 decode(eea.flg_time,
                                        pk_exam_constant.g_flg_time_n,
                                        pk_exam_constant.g_no,
                                        pk_exam_constant.g_yes))) avail_button_cancel,
                   pk_date_utils.date_send_tsz(i_lang, nvl(nvl(eea.dt_pend_req, eea.dt_begin), eea.dt_req), i_prof) dt_ord,
                   eea.id_task_dependency,
                   pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_REQ_ORIGIN_MODULE', eea.flg_req_origin_module) icon_name
              FROM (SELECT eea.*
                      FROM episode e
                      JOIN exams_ea eea
                        ON (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode)
                     WHERE e.id_patient = i_patient
                    UNION ALL
                    SELECT eea.*
                      FROM episode e
                      JOIN exams_ea eea
                        ON eea.id_prev_episode = e.id_episode
                     WHERE e.id_patient = i_patient) eea,
                   exam_req er,
                   (SELECT *
                      FROM exam_dep_clin_serv
                     WHERE flg_type = pk_exam_constant.g_exam_can_req
                       AND id_institution = i_prof.institution
                       AND id_software = i_prof.software) edcs,
                   episode ep
             WHERE (ep.id_episode = eea.id_episode OR ep.id_episode = eea.id_episode_origin)
               AND eea.id_exam_req = er.id_exam_req
               AND er.id_episode_destination IS NULL
               AND eea.id_exam = edcs.id_exam(+)
               AND ((nvl(edcs.id_exam, 0) != 0 AND eea.flg_available = pk_exam_constant.g_yes) OR
                   eea.flg_available = pk_exam_constant.g_no)
               AND EXISTS (SELECT 1
                      FROM exam_cat_dcs ecd, prof_dep_clin_serv pdcs
                     WHERE ecd.id_exam_cat = eea.id_exam_cat
                       AND ecd.id_dep_clin_serv = pdcs.id_dep_clin_serv
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = pk_exam_constant.g_selected
                       AND pdcs.id_institution = i_prof.institution)
             ORDER BY id_exam_type DESC,
                      exam_group,
                      pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det),
                      dt_ord DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_list;

    FUNCTION get_exam_list_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN table_number,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_date sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'EXAM_REQ_M002');
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT eea.id_exam_req_det,
                   pk_exam_utils.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', eea.flg_time, NULL) to_be_perform,
                   pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.PRIORITY', eea.priority, NULL) priority,
                   decode(eea.flg_time,
                          pk_exam_constant.g_flg_time_e,
                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', eea.flg_time, NULL) ||
                          decode(eea.dt_begin,
                                 NULL,
                                 decode(er.dt_schedule_tstz,
                                        NULL,
                                        '',
                                        chr(10) || pk_date_utils.date_char_tsz(i_lang,
                                                                               er.dt_schedule_tstz,
                                                                               i_prof.institution,
                                                                               i_prof.software) || l_msg_date || ''),
                                 chr(10) || pk_date_utils.date_char_tsz(i_lang,
                                                                        er.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || ''),
                          pk_exam_constant.g_flg_time_b,
                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', eea.flg_time, NULL) ||
                          decode(er.dt_begin_tstz,
                                 NULL,
                                 decode(er.dt_schedule_tstz,
                                        NULL,
                                        '',
                                        chr(10) || pk_date_utils.date_char_tsz(i_lang,
                                                                               er.dt_schedule_tstz,
                                                                               i_prof.institution,
                                                                               i_prof.software) || ' ' || l_msg_date),
                                 chr(10) || pk_date_utils.date_char_tsz(i_lang,
                                                                        er.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || ''),
                          pk_exam_constant.g_flg_time_d,
                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', eea.flg_time, NULL) ||
                          decode(er.dt_begin_tstz,
                                 NULL,
                                 decode(er.dt_schedule_tstz,
                                        NULL,
                                        '',
                                        chr(10) || pk_date_utils.date_char_tsz(i_lang,
                                                                               er.dt_schedule_tstz,
                                                                               i_prof.institution,
                                                                               i_prof.software) || ' ' || l_msg_date),
                                 chr(10) || pk_date_utils.date_char_tsz(i_lang,
                                                                        er.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || ''),
                          pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ.FLG_TIME', eea.flg_time, NULL)) desc_time,
                   er.flg_time,
                   pk_date_utils.date_send_tsz(i_lang, er.dt_begin_tstz, i_prof) dt_begin,
                   er.notes,
                   er.notes_patient
              FROM exams_ea eea, exam_req er
             WHERE eea.id_exam_req_det IN (SELECT column_value
                                             FROM TABLE(i_exam_req_det))
               AND eea.id_exam_req = er.id_exam_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EXAM_LIST_EDIT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_exam_list_edit;

    FUNCTION get_hpi_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_type       IN epis_type.id_epis_type%TYPE,
        o_title_anamnesis OUT VARCHAR2,
        o_anamnesis       OUT VARCHAR2,
        o_title_diagnosis OUT VARCHAR2,
        o_diagnosis       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_episode episode.id_episode%TYPE;
    
        l_cur_epis_complaint pk_complaint.epis_complaint_cur;
        l_row_epis_complaint pk_complaint.epis_complaint_rec;
    
        l_desc_triage      VARCHAR2(1000 CHAR);
        l_anamnesis_cursor pk_types.cursor_type;
        l_prof             professional.id_professional%TYPE;
        l_prof_name        VARCHAR2(1000 CHAR);
    
        l_anamnesis VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_epis_type = pk_alert_constant.g_epis_type_emergency
        THEN
        
            g_error           := 'GET O_TITLE_ANAMNESIS';
            o_title_anamnesis := pk_message.get_message(i_lang, 'EXAMS_T042');
        
            g_error := 'GET EMERGENCY COMPLAINT';
            IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => i_episode,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_no,
                                                   o_epis_complaint => l_cur_epis_complaint,
                                                   o_error          => o_error)
            THEN
                RETURN NULL;
            END IF;
        
            g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
            FETCH l_cur_epis_complaint
                INTO l_row_epis_complaint;
            CLOSE l_cur_epis_complaint;
        
            o_anamnesis := pk_complaint.get_epis_complaint_desc(i_lang,
                                                                i_prof,
                                                                l_row_epis_complaint.desc_complaint,
                                                                l_row_epis_complaint.patient_complaint,
                                                                pk_alert_constant.g_no);
        
        ELSE
            IF i_epis_type = pk_alert_constant.g_epis_type_outpatient
            THEN
                g_error           := 'GET O_TITLE_ANAMNESIS';
                o_title_anamnesis := pk_message.get_message(i_lang, 'EXAMS_T041');
            ELSE
                g_error           := 'GET O_TITLE_ANAMNESIS';
                o_title_anamnesis := pk_message.get_message(i_lang, 'EXAMS_T042');
            END IF;
        
            IF i_epis_type = pk_alert_constant.g_epis_type_inpatient
            THEN
                BEGIN
                    g_error := 'GET PREV EPIS';
                    SELECT e2.id_episode
                      INTO l_episode
                      FROM episode e1, episode e2
                     WHERE e1.id_episode = i_episode
                       AND e2.id_episode(+) = e1.id_prev_episode
                       AND e2.id_epis_type(+) = pk_alert_constant.g_epis_type_emergency;
                
                    g_error           := 'GET O_TITLE_ANAMNESIS';
                    o_title_anamnesis := pk_message.get_message(i_lang, 'EXAMS_T042');
                
                    g_error := 'GET EMERGENCY COMPLAINT';
                    IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => l_episode,
                                                           i_epis_docum     => NULL,
                                                           i_flg_only_scope => pk_alert_constant.g_no,
                                                           o_epis_complaint => l_cur_epis_complaint,
                                                           o_error          => o_error)
                    THEN
                        RETURN NULL;
                    END IF;
                
                    g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
                    FETCH l_cur_epis_complaint
                        INTO l_row_epis_complaint;
                    CLOSE l_cur_epis_complaint;
                
                    o_anamnesis := pk_complaint.get_epis_complaint_desc(i_lang,
                                                                        i_prof,
                                                                        l_row_epis_complaint.desc_complaint,
                                                                        l_row_epis_complaint.patient_complaint,
                                                                        pk_alert_constant.g_no);
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            g_error := 'CALL PK_CLINICAL_INFO.GET_SUMM_LAST_ANAMNESIS';
            IF NOT pk_clinical_info.get_summ_last_anamnesis(i_lang      => i_lang,
                                                            i_episode   => i_episode,
                                                            i_prof      => i_prof,
                                                            i_flg_type  => 'C',
                                                            o_anamnesis => l_anamnesis_cursor,
                                                            o_error     => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'FECH L_COMPLAINT';
            FETCH l_anamnesis_cursor
                INTO l_anamnesis, l_prof, l_prof_name;
            CLOSE l_anamnesis_cursor;
        
            o_anamnesis := o_anamnesis || chr(13) || l_anamnesis;
        END IF;
    
        g_error := 'OPEN C_COMPLAINT_TRIAGE';
        BEGIN
            SELECT desc_triage
              INTO l_desc_triage
              FROM (SELECT nvl2(et.id_triage_white_reason,
                                pk_translation.get_translation(i_lang,
                                                               'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                               et.id_triage_white_reason) || ': ' || et.notes,
                                '') desc_triage
                      FROM epis_triage et
                     WHERE et.id_episode = i_episode
                     ORDER BY et.dt_end_tstz DESC)
             WHERE rownum < 2;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_desc_triage IS NOT NULL
           AND o_anamnesis IS NOT NULL
        THEN
            o_anamnesis := o_anamnesis || chr(13) || l_desc_triage;
        ELSIF l_desc_triage IS NOT NULL
        THEN
            o_anamnesis := l_desc_triage;
        END IF;
    
        g_error           := 'GET O_TITLE_DIAGNOSIS';
        o_title_diagnosis := pk_message.get_message(i_lang, 'EXAMS_T043');
    
        g_error := 'OPEN O_DIAGNOSIS';
        OPEN o_diagnosis FOR
            SELECT (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_alert_diagnosis => NULL,
                                                      i_id_diagnosis       => d.id_diagnosis,
                                                      i_code               => d.code_icd,
                                                      i_flg_other          => d.flg_other,
                                                      i_flg_std_diag       => pk_alert_constant.g_yes,
                                                      i_epis_diag          => ed.id_epis_diagnosis)
                      FROM diagnosis d
                     WHERE d.id_diagnosis = ed.id_diagnosis) desc_diagnosis
              FROM epis_diagnosis ed
             WHERE ed.id_episode = i_episode
               AND ed.flg_type IN ('P', 'D', 'B')
             ORDER BY nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz) DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HPI_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_hpi_summary;

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
    
        l_num_days_back sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK',
                                                                         l_prof);
    
        --FILTER_BIND
        l_prof_cat category.flg_type%TYPE;
    
        l_today    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        g_sysdate_char VARCHAR(50 CHAR);
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        o_error t_error_out;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(l_lang, g_sysdate_tstz, l_prof);
    
        l_today := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz);
    
        l_prof_cat := pk_prof_utils.get_category(l_lang, l_prof);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
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
    
        DELETE grid_task_oth_exm gtoe
         WHERE gtoe.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtoe.id_epis_type != pk_exam_constant.g_episode_type_exm;
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := l_dt_begin + INTERVAL '1' DAY;
    
        DELETE grid_task_oth_exm gtoe
         WHERE gtoe.flg_status_req_det IN (pk_exam_constant.g_exam_read, pk_exam_constant.g_exam_cancel)
           AND gtoe.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
           AND gtoe.flg_status_epis = pk_alert_constant.g_epis_status_inactive
           AND gtoe.id_epis_type = pk_exam_constant.g_episode_type_exm;
    
        COMMIT;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz) - INTERVAL '4' hour;
        l_dt_end   := l_dt_begin + INTERVAL '28' DAY;
    
        pk_context_api.set_parameter('i_dt_begin', l_dt_begin);
        pk_context_api.set_parameter('i_dt_end', l_dt_end);
        pk_context_api.set_parameter('i_date_today', l_today);
    
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
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_IMAGE_TECH',
                                              i_function => 'INIT_PARAMS_GRID',
                                              o_error    => o_error);
    END init_params_grid;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_exams;
/
