CREATE OR REPLACE VIEW V_EXAM_SCHEDULED AS
SELECT id_patient,
       gender,
       pat_age,
       num_clin_record,
       id_schedule,
       no_show,
       decode(no_show, 'Y', NULL, id_episode) id_episode,
       flg_status_epis,
       id_institution,
       MAX(id_dept) id_dept,
       MAX(id_clinical_service) id_clinical_service,
       flg_type,
       --substr(concatenate_clob(id_exam_req || ';'), 1, length(concatenate_clob(id_exam_req || ';')) - 1) id_req,
       listagg(id_exam_req, ';') id_req,
       listagg(id_exam_req_det, ';') id_req_det,
       dt_begin_tstz,
       id_room,
       MAX(flg_status_req_det) flg_status_req_det,
       id_task_dependency,
       flg_req_origin_module,
       id_episode g_episode,
       flg_status s_flg_status,
       flg_ehr,
       s_id_dcs_requested,
       type_icon
  FROM (SELECT /*+ opt_estimate(table s rows=1) */
        DISTINCT gti.id_patient,
                 gti.pat_gender gender,
                 to_char(gti.pat_age) pat_age,
                 gti.num_clin_record,
                 s.id_schedule,
                 s.no_show,
                 gti.id_episode,
                 gti.flg_status_epis,
                 gti.id_institution,
                 gti.id_dept,
                 gti.id_clinical_service,
                 'EI' flg_type,
                 gti.id_exam,
                 gti.id_exam_req,
                 gti.id_exam_req_det,
                 s.dt_begin dt_begin_tstz,
                 ei.id_room,
                 decode(s.flg_status, 'C', 'NR', gti.flg_status_req_det) flg_status_req_det,
                 gti.id_task_dependency,
                 decode(gti.flg_req_origin_module, 'O', 'O', NULL) flg_req_origin_module,
                 s.flg_status,
                 e.flg_ehr,
                 (SELECT sc.id_dcs_requested
                    FROM schedule sc
                   WHERE sc.id_schedule = s.id_schedule) s_id_dcs_requested,
                 'ImageExameIcon' type_icon
          FROM grid_task_img gti,
               exam_cat_dcs ecd,
               epis_info ei,
               TABLE(pk_schedule_exam.get_today_exam_appoints(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                              profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                           sys_context('ALERT_CONTEXT',
                                                                                       'i_prof_institution'),
                                                                           sys_context('ALERT_CONTEXT', 'i_prof_software')))) s,
               episode e
         WHERE gti.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND (gti.flg_time_req IN ('D', 'B') OR
               (gti.flg_time_req = 'E' AND (gti.id_episode IS NULL OR gti.id_epis_type = 13)))
           AND gti.id_exam_cat = ecd.id_exam_cat
           AND EXISTS (SELECT 1
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                   AND pdcs.flg_status = 'S'
                   AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                   AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv)
           AND gti.id_episode = ei.id_episode(+)
           AND gti.id_episode = e.id_episode(+)
           AND gti.id_exam_req = s.id_exam_req
           AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 15, 12, 39)
        UNION ALL
        SELECT /*+ opt_estimate(table s rows=1) */
        DISTINCT gtoe.id_patient,
                 gtoe.gender,
                 gtoe.pat_age,
                 gtoe.num_clin_record,
                 s.id_schedule,
                 s.no_show,
                 gtoe.id_episode,
                 gtoe.flg_status_epis,
                 gtoe.id_institution,
                 gtoe.id_dept,
                 gtoe.id_clinical_service,
                 'EO' flg_type,
                 gtoe.id_exam,
                 gtoe.id_exam_req,
                 gtoe.id_exam_req_det,
                 s.dt_begin dt_begin_tstz,
                 ei.id_room,
                 decode(s.flg_status, 'C', 'NR', gtoe.flg_status_req_det) flg_status_req_det,
                 gtoe.id_task_dependency,
                 decode(gtoe.flg_req_origin_module, 'O', 'O', NULL) flg_req_origin_module,
                 s.flg_status,
                 e.flg_ehr,
                 (SELECT sc.id_dcs_requested
                    FROM schedule sc
                   WHERE sc.id_schedule = s.id_schedule) s_id_dcs_requested,
                 'TechnicianInContact' type_icon
          FROM grid_task_oth_exm gtoe,
               exam_cat_dcs ecd,
               epis_info ei,
               TABLE(pk_schedule_exam.get_today_exam_appoints(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                              profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                           sys_context('ALERT_CONTEXT',
                                                                                       'i_prof_institution'),
                                                                           sys_context('ALERT_CONTEXT', 'i_prof_software')))) s,
               episode e
         WHERE gtoe.flg_type = 'E'
           AND gtoe.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND (gtoe.flg_time IN ('D', 'B') OR
               (gtoe.flg_time = 'E' AND (gtoe.id_episode IS NULL OR gtoe.id_epis_type = 21)))
           AND gtoe.id_exam_cat = ecd.id_exam_cat
           AND EXISTS (SELECT 1
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                   AND pdcs.flg_status = 'S'
                   AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                   AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv)
           AND gtoe.id_episode = ei.id_episode(+)
           AND gtoe.id_episode = e.id_episode(+)
           AND gtoe.id_exam_req = s.id_exam_req
           AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 25, 12, 39))
 GROUP BY id_patient,
          gender,
          pat_age,
          num_clin_record,
          id_schedule,
          no_show,
          id_episode,
          flg_status_epis,
          id_institution,
          flg_type,
          dt_begin_tstz,
          id_room,
          id_task_dependency,
          flg_req_origin_module,
          id_episode,
          flg_status,
          flg_ehr,
          s_id_dcs_requested,
          type_icon;