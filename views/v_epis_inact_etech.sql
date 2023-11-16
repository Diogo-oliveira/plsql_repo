CREATE OR REPLACE VIEW V_EPIS_INACT_ETECH AS
SELECT /*+ use_nl(t t1 ei epis pat cr)*/
 ei.triage_rank_acuity rank,
 ei.triage_acuity acuity,
 ei.id_software,
 ei.dt_first_obs_tstz,
 ei.id_professional,
 pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                         profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                      sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                      sys_context('ALERT_CONTEXT', 'i_prof_software')),
                         epis.id_patient,
                         epis.id_episode,
                         NULL) name_pat,
 pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                              sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                 epis.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                 sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                    epis.id_patient) pat_nd_icon,
 epis.id_patient,
 epis.id_institution,
 epis.dt_begin_tstz,
 t1.dt_begin dt_target,
 epis.barcode,
 pat.gender,
 pat.dt_birth,
 pat.dt_birth_hijri,
 pat.age,
 cr.num_clin_record,
 epis.id_episode,
 ei.id_schedule,
 t.id_task,
 t1.priority,
 (SELECT pk_utils.get_status_string(sys_context('ALERT_CONTEXT', 'i_lang'),
                                    profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                 sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                 sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                    t1.status_str_req,
                                    t1.status_msg_req,
                                    t1.status_icon_req,
                                    t1.status_flg_req)
    FROM dual) status_string,
 t.flg_result,
 t.flg_contact,
 (SELECT so.flg_state
    FROM schedule_outp so
   WHERE so.id_schedule = ei.id_schedule) flg_state,
 t1.flg_status_det flg_status,
 id_dept,
 id_clinical_service,
 epis.id_fast_track,
 t1.id_req,
 t1.id_harvest,
 ei.triage_color_text color_text,
 ei.id_triage_color,
 t1.id_task_dependency,
 t1.flg_req_origin_module,
 pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                              sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                              sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                 epis.id_patient,
                                 epis.id_episode,
                                 NULL) order_name,
 t.flg_status_mov,
 t.flg_status flg_status_req_det,
 t.dt_req_tstz,
 t.dt_pend_req_tstz,
 CAST(NULL AS TIMESTAMP(6)) AS dt_target_tstz,
 CAST(NULL AS TIMESTAMP(6)) AS dt_harvest_tstz,
 t.dt_begin_tstz dt_begin_tstz_er,
 t.dt_end_mov_tstz,
 t.dt_req_mov_tstz,
 CAST(NULL AS TIMESTAMP(6)) AS dt_lab_reception_tstz,
 t.flg_referral,
 t.flg_time flg_time_req,
 t.flg_status_r
  FROM episode epis,
       epis_info ei,
       patient pat,
       clin_record cr,
       (SELECT er.id_episode,
               erd.id_exam_req_det id_req,
               erd.id_exam id_task,
               CAST(NULL AS VARCHAR2(4000)) harvest,
               decode(eres.id_exam_result, NULL, 'N', 'Y') flg_result,
               erd.flg_status,
               er.flg_time,
               erd.flg_referral,
               CASE
                    WHEN erd.flg_status = 'F' THEN
                     CASE
                         WHEN erd.flg_priority != 'N' THEN
                          rs.value || 'U'
                         ELSE
                          CASE
                              WHEN eres.id_abnormality IS NOT NULL
                                   AND eres.id_abnormality != 7 THEN
                               rs.value || 'U'
                              ELSE
                               rs.value
                          END
                     END
                    ELSE
                     rs.value
                END flg_status_r,
               er.dt_req_tstz,
               er.dt_pend_req_tstz,
               er.dt_begin_tstz,
               m.flg_status flg_status_mov,
               m.dt_req_tstz dt_req_mov_tstz,
               m.dt_end_tstz dt_end_mov_tstz,
               er.flg_contact
          FROM exam_req_det erd
          JOIN exam_req er
            ON er.id_exam_req = erd.id_exam_req
          LEFT JOIN exam_result eres
            ON eres.id_exam_req_det = erd.id_exam_req_det
           AND eres.flg_status <> 'C'
          LEFT JOIN result_status rs
            ON rs.id_result_status = eres.id_result_status
          LEFT JOIN movement m
            ON m.id_movement = erd.id_movement
         WHERE erd.flg_status <> 'C'
           AND (EXISTS (SELECT 1
                          FROM institution i
                         WHERE i.id_parent =
                               (SELECT i.id_parent
                                  FROM institution i
                                 WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                           AND i.id_institution = er.id_institution) OR
                er.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))) t,
       (SELECT eea.id_episode,
               eea.id_exam_req_det id_req,
               eea.flg_status_det,
               CAST(NULL AS NUMBER) id_harvest,
               eea.dt_begin,
               eea.priority,
               eea.status_str_req,
               eea.status_msg_req,
               eea.status_icon_req,
               eea.status_flg_req,
               eea.id_task_dependency,
               eea.flg_req_origin_module
          FROM exams_ea eea
         WHERE eea.flg_type = 'E'
           AND eea.flg_status_det NOT IN ('DF', 'C')) t1
 WHERE t1.id_episode = t.id_episode(+)
   AND ei.id_episode = epis.id_episode
   AND epis.flg_status NOT IN ('A', 'C')
   AND epis.flg_ehr = 'N'
   AND epis.id_episode = t1.id_episode(+)
   AND t.id_req = t1.id_req
   AND pat.id_patient = epis.id_patient
   AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
   AND cr.id_patient = epis.id_patient
   AND cr.id_institution = epis.id_institution
   AND cr.flg_status = 'A'
 ORDER BY pat.name;
/
