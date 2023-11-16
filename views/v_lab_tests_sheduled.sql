CREATE OR REPLACE VIEW V_LAB_TEST_SCHEDULED AS
SELECT id_patient,
       nvl(gender, pk_patient.get_pat_gender(id_patient)) gender,
       nvl(pat_age,
           pk_patient.get_pat_age(sys_context('ALERT_CONTEXT', 'i_lang'),
                                  id_patient,
                                  profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                               sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                               sys_context('ALERT_CONTEXT', 'i_prof_software')))) pat_age,
       num_clin_record,
       id_schedule,
       no_show,
       decode(no_show, 'Y', NULL, id_episode) id_episode,
       flg_status_epis,
       id_institution,
       MAX(id_dept) id_dept,
       MAX(id_clinical_service) id_clinical_service,
       flg_type,
       listagg(id_analysis_req, ';') id_req,
       listagg(id_analysis_req_det, ';') id_req_det,
       dt_begin_tstz,
       id_room,
       MAX(flg_status_req_det) flg_status_req_det,
       id_task_dependency,
       flg_req_origin_module,
       id_episode g_episode,
       flg_status s_flg_status,
       flg_ehr,
       s_id_dcs_requested,
       'LaboratorialAnalysisIcon' type_icon
  FROM (SELECT /*+ opt_estimate(table s rows=1) use_nl(ard ecd pdcs) */
        DISTINCT gtl.id_patient,
                 gtl.gender,
                 to_char(gtl.pat_age) pat_age,
                 gtl.num_clin_record,
                 s.id_schedule,
                 s.no_show,
                 gtl.id_episode,
                 gtl.flg_status_epis,
                 gtl.id_institution,
                 gtl.id_dept,
                 gtl.id_clinical_service,
                 'A' flg_type,
                 gtl.id_analysis,
                 gtl.id_sample_type,
                 gtl.id_analysis_req,
                 gtl.id_analysis_req_det,
                 s.dt_begin dt_begin_tstz,
                 ei.id_room,
                 CASE
                      WHEN gtl.flg_status_ard = 'X'
                           AND ard.flg_col_inst = 'Y' THEN
                       'D'
                      ELSE
                       gtl.flg_status_ard
                  END flg_status_req_det,
                 gtl.id_task_dependency,
                 gtl.flg_req_origin_module,
                 s.flg_status,
                 e.flg_ehr,
                 (SELECT sc.id_dcs_requested
                    FROM schedule sc
                   WHERE sc.id_schedule = s.id_schedule) s_id_dcs_requested
          FROM grid_task_lab gtl,
               analysis_req_det ard,
               exam_cat_dcs ecd,
               epis_info ei,
               episode e,
               (SELECT *
                  FROM TABLE(pk_schedule_lab.get_today_lab_appoints(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                                 sys_context('ALERT_CONTEXT',
                                                                                             'i_prof_institution'),
                                                                                 sys_context('ALERT_CONTEXT',
                                                                                             'i_prof_software'))))) s
         WHERE gtl.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND (gtl.flg_time_harvest IN ('B', 'D') OR
               (gtl.flg_time_harvest = 'E' AND (gtl.id_episode IS NULL OR gtl.id_epis_type = 12)))
           AND gtl.id_analysis_req_det = ard.id_analysis_req_det
           AND ard.id_exam_cat = ecd.id_exam_cat
           AND EXISTS (SELECT 1
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                   AND pdcs.flg_status = 'S'
                   AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                   AND pdcs.id_dep_clin_serv = ecd.id_dep_clin_serv)
           AND gtl.id_episode = ei.id_episode(+)
           AND gtl.id_episode = e.id_episode(+)
           AND gtl.id_analysis_req = s.id_analysis_req
           AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 3, 12, 16, 39)
        UNION ALL
        SELECT /*+ opt_estimate(table s rows=1)*/
        DISTINCT s.id_patient,
                 NULL gender,
                 NULL pat_age,
                 (SELECT cr.num_clin_record
                    FROM clin_record cr
                   WHERE cr.id_patient = s.id_patient
                     AND cr.id_institution = s.id_inst_requests
                     AND cr.id_instit_enroled = s.id_inst_requests
                     AND cr.flg_status = 'A'
                     AND cr.num_clin_record IS NOT NULL) num_clin_record,
                 s.id_schedule,
                 s.no_show,
                 ei.id_episode,
                 gtl.flg_status_epis,
                 s.id_inst_requests id_institution,
                 NULL id_dept,
                 NULL id_clinical_service,
                 'A' flg_type,
                 gtl.id_analysis,
                 gtl.id_sample_type,
                 gtl.id_analysis_req,
                 gtl.id_analysis_req_det,
                 s.dt_begin dt_begin_tstz,
                 ei.id_room,
                 gtl.flg_status_ard flg_status_req_det,
                 NULL id_task_dependency,
                 NULL flg_req_origin_module,
                 s.flg_status,
                 e.flg_ehr,
                 (SELECT sc.id_dcs_requested
                    FROM schedule sc
                   WHERE sc.id_schedule = s.id_schedule) s_id_dcs_requested
          FROM TABLE(pk_schedule_lab.get_today_lab_appoints(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                            profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                         sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                         sys_context('ALERT_CONTEXT', 'i_prof_software')))) s
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          LEFT JOIN grid_task_lab gtl
            ON gtl.id_episode = ei.id_episode
          LEFT JOIN episode e
            ON e.id_episode = gtl.id_episode
         WHERE s.id_analysis_req IS NULL
           AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 3, 12, 16, 39))
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
          s_id_dcs_requested;