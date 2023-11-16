CREATE OR REPLACE VIEW V_LAB_TEST_ADT AS
SELECT t.id_patient,
       t.pat_age,
       t.gender,
       t.num_clin_record,
       t.id_episode,
       listagg(t.id_analysis_req, ';') id_req,
       listagg(t.id_analysis_req_det, ';') id_req_det,
       t.id_institution,
       t.id_software,
       t.acuity,
       t.rank_acuity,
       t.id_epis_type,
       NULL id_fast_track,
       t.id_triage_color,
       t.dt_first_obs_tstz,
       NULL dt_first_obs,
       'A' flg_type,
       'LaboratorialAnalysisIcon' type_icon
  FROM (SELECT gtl.id_patient,
               to_char(gtl.pat_age) pat_age,
               gtl.gender,
               gtl.num_clin_record,
               s.id_schedule,
               gtl.id_episode,
               gtl.id_analysis,
               gtl.id_sample_type,
               gtl.id_analysis_req,
               gtl.id_analysis_req_det,
               gtl.id_institution,
               gtl.id_software,
               gtl.acuity,
               gtl.rank_acuity,
               gtl.id_epis_type,
               gtl.id_triage_color,
               gtl.dt_first_obs_tstz
          FROM grid_task_lab gtl
          JOIN analysis_req_det ard
            ON gtl.id_analysis_req_det = ard.id_analysis_req_det
          JOIN (SELECT *
                 FROM TABLE(pk_schedule_lab.get_today_lab_appoints(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                   profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                                sys_context('ALERT_CONTEXT',
                                                                                            'i_prof_institution'),
                                                                                sys_context('ALERT_CONTEXT',
                                                                                            'i_prof_software')),
                                                                   current_timestamp))) s
            ON gtl.id_analysis_req = s.id_analysis_req
         WHERE gtl.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND (gtl.flg_time_harvest IN ('B', 'D') OR
               (gtl.flg_time_harvest = 'E' AND (gtl.id_episode IS NULL OR gtl.id_epis_type = 12)))
           AND EXISTS
         (SELECT 1
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                   AND pdcs.flg_status = 'S'
                   AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                   AND pdcs.id_dep_clin_serv IN (SELECT ecd.id_dep_clin_serv
                                                   FROM exam_cat_dcs ecd
                                                  WHERE ecd.id_exam_cat = gtl.id_exam_cat))
           AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 3, 12, 16, 39)
        UNION ALL
        SELECT gtl.id_patient,
               to_char(gtl.pat_age) pat_age,
               gtl.gender,
               gtl.num_clin_record,
               NULL id_schedule,
               gtl.id_episode,
               gtl.id_analysis,
               gtl.id_sample_type,
               gtl.id_analysis_req,
               gtl.id_analysis_req_det,
               gtl.id_institution,
               gtl.id_software,
               gtl.acuity,
               gtl.rank_acuity,
               gtl.id_epis_type,
               gtl.id_triage_color,
               gtl.dt_first_obs_tstz
          FROM grid_task_lab gtl
         WHERE (EXISTS (SELECT 1
                          FROM institution i
                         WHERE i.id_parent =
                               (SELECT i.id_parent
                                  FROM institution i
                                 WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                           AND i.id_institution = gtl.id_institution) OR
                gtl.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
           AND ((gtl.flg_time_harvest = 'E' AND gtl.flg_status_epis = 'A' AND
               ((gtl.flg_status_ard IN ('R', 'CC', 'E', 'F')) OR
               (gtl.flg_status_ard IN ('R', 'D', 'CC', 'E', 'F') AND
               nvl(sys_context('ALERT_CONTEXT', 'l_collect_pending'), 'Y') = 'Y'))) OR
               (gtl.flg_time_harvest IN ('B', 'D') AND
               nvl(gtl.dt_target_tstz, gtl.dt_order) BETWEEN trunc(current_timestamp) AND trunc(current_timestamp + 1) AND
               gtl.flg_status_ard NOT IN ('PA', 'A')) OR
               (gtl.flg_time_harvest = 'N' AND gtl.flg_status_epis = 'A' AND
               ((gtl.flg_status_ard IN ('R', 'CC', 'E', 'F')) OR
               (gtl.flg_status_ard IN ('R', 'D', 'CC', 'E', 'F') AND
               nvl(sys_context('ALERT_CONTEXT', 'l_collect_pending'), 'Y') = 'Y'))))
           AND EXISTS (SELECT 1
                  FROM prof_room pr
                 WHERE pr.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                   AND pr.id_room = nvl(gtl.id_room_receive_tube, gtl.id_room_req))
              -- End fix
              -- Dept with data, clinical_service with data, dep_clin_serv with data
           AND ((EXISTS (SELECT 1
                           FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                          WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                            AND pdcs.id_institution = gtl.id_institution
                            AND pdcs.flg_status = 'S'
                            AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                            AND dcs.id_department = d.id_department
                            AND dcs.id_dep_clin_serv = gtl.id_dep_clin_serv
                            AND dcs.id_clinical_service = gtl.id_clinical_service
                            AND d.id_dept = gtl.id_dept)) OR
               -- Dept with data, clinical_service with data, dep_clin_serv is NULL
               (gtl.id_dep_clin_serv IS NULL AND EXISTS
                (SELECT 1
                    FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                   WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                     AND pdcs.id_institution = gtl.id_institution
                     AND pdcs.flg_status = 'S'
                     AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     AND dcs.id_clinical_service = gtl.id_clinical_service
                     AND dcs.id_department = d.id_department
                     AND d.id_dept = gtl.id_dept)) OR
               -- Dept with data, clinical_service IS NULL, dep_clin_serv is NULL
               (gtl.id_dep_clin_serv IS NULL AND gtl.id_clinical_service IS NULL AND EXISTS
                (SELECT 1
                    FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                   WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                     AND pdcs.id_institution = gtl.id_institution
                     AND pdcs.flg_status = 'S'
                     AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     AND dcs.id_department = d.id_department
                     AND d.id_dept = gtl.id_dept)) OR
               -- Dept is NULL, clinical_service with data, dep_clin_serv with data
               (gtl.id_dept IS NULL AND EXISTS
                (SELECT 1
                    FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs
                   WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                     AND pdcs.id_institution = gtl.id_institution
                     AND pdcs.flg_status = 'S'
                     AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     AND dcs.id_dep_clin_serv = gtl.id_dep_clin_serv
                     AND dcs.id_clinical_service = gtl.id_clinical_service)) OR
               -- Dept is NULL, clinical_service is NULL, dep_clin_serv with data
               (gtl.id_dept IS NULL AND gtl.id_clinical_service IS NULL AND EXISTS
                (SELECT 1
                    FROM prof_dep_clin_serv pdcs
                   WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                     AND pdcs.id_institution = gtl.id_institution
                     AND pdcs.flg_status = 'S'
                     AND pdcs.id_dep_clin_serv = gtl.id_dep_clin_serv)) OR
               -- Dept is NULL, clinical_service is NULL, dep_clin_serv is NULL
               (gtl.id_dep_clin_serv IS NULL AND gtl.id_clinical_service IS NULL AND gtl.id_dept IS NULL) OR
               -- Dept with data, clinical_service is -1, dep_clin_serv is NULL (LAB episodes)
               (gtl.id_dep_clin_serv IS NULL AND gtl.id_clinical_service = -1 AND EXISTS
                (SELECT 1
                    FROM prof_dep_clin_serv pdcs, dep_clin_serv dcs, department d
                   WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                     AND pdcs.id_institution = gtl.id_institution
                     AND pdcs.flg_status = 'S'
                     AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     AND dcs.id_department = d.id_department
                     AND d.id_dept = gtl.id_dept)))
           AND gtl.id_announced_arrival IS NOT NULL) t
 GROUP BY t.id_patient,
          t.pat_age,
          t.gender,
          t.num_clin_record,
          t.id_episode,
          t.id_institution,
          t.id_software,
          t.acuity,
          t.rank_acuity,
          t.id_epis_type,
          t.id_triage_color,
          t.dt_first_obs_tstz;