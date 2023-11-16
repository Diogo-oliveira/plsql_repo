CREATE OR REPLACE VIEW V_EPIS_ACTIVE_ITECH AS
SELECT v.triage_rank_acuity rank,
       v.triage_acuity color,
       v.dt_first_obs_tstz,
       pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                               profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                            sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                            sys_context('ALERT_CONTEXT', 'i_prof_software')),
                               v.id_patient,
                               v.id_episode,
                               NULL) name_pat,
       pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                       v.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                          profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                       sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                       sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                          v.id_patient) pat_nd_icon,
       v.id_patient,
       v.id_episode,
       v.id_schedule,
       v.id_software,
       v.id_epis_type,
       v.id_institution,
       (SELECT cr.num_clin_record
          FROM clin_record cr
         WHERE cr.id_patient = v.id_patient
           AND cr.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND cr.flg_status = 'A'
           AND rownum <= 1) num_clin_record,
       pat.dt_birth,
       pat.dt_birth_hijri,
       v.dt_begin_tstz_e dt_begin_tstz_epis,
       (SELECT p.nick_name
          FROM professional p
         WHERE p.id_professional = v.id_professional) name_prof,
       v.barcode_e barcode,
       er.code_exam,
       er.flg_status,
       v.id_fast_track,
       pat.gender,
       pat.age,
       er.dt_begin_tstz,
       (SELECT d.id_dept
          FROM department d
         WHERE d.id_department = dcs.id_department) id_dept,
       dcs.id_clinical_service,
       er.priority,
       er2.request,
       er2.transport,
       er2.execute,
       er2.complete,
       (SELECT pk_utils.get_status_string(sys_context('ALERT_CONTEXT', 'i_lang'),
                                          profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                       sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                       sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                          er.status_str_req,
                                          er.status_msg_req,
                                          er.status_icon_req,
                                          er.status_flg_req)
          FROM dual) status_string,
       er2.flg_result,
       er2.flg_contact,
       (SELECT so.flg_state
          FROM schedule_outp so
         WHERE so.id_schedule = v.id_schedule) flg_state,
       v.id_triage_color,
       v.triage_color_text color_text,
       er.id_task_dependency,
       er.flg_req_origin_module,
       pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                       v.id_patient,
                                       v.id_episode,
                                       NULL) order_name
  FROM v_episode_act_pend v,
       patient pat,
       dep_clin_serv dcs,
       (SELECT gt.id_exam_req,
               gt.id_exam_req_det,
               gt.id_episode,
               gt.request,
               gt.transport,
               gt.execute,
               gt.complete,
               NULL               flg_result,
               NULL               flg_contact
          FROM grid_task_img gt
         WHERE sys_context('ALERT_CONTEXT', 'i_prof_software') = sys_context('ALERT_CONTEXT', 'itech_software')
           AND ((sys_context('ALERT_CONTEXT', 'l_search_concluded') = 'N' AND gt.flg_status_req_det NOT IN ('C', 'NR')) OR
                sys_context('ALERT_CONTEXT', 'l_search_concluded') = 'Y')
        UNION ALL
        SELECT gt.id_exam_req,
               gt.id_exam_req_det,
               gt.id_episode,
               NULL               request,
               NULL               transport,
               NULL               EXECUTE,
               NULL               complete,
               gt.flg_result,
               gt.flg_contact
          FROM grid_task_oth_exm gt
         WHERE sys_context('ALERT_CONTEXT', 'i_prof_software') = sys_context('ALERT_CONTEXT', 'exams_software')
           AND ((sys_context('ALERT_CONTEXT', 'l_search_concluded') = 'N' AND gt.flg_status_req_det NOT IN ('C', 'NR')) OR
                sys_context('ALERT_CONTEXT', 'l_search_concluded') = 'Y')) er2,
       (SELECT ea.id_exam_req,
               ea.id_exam_req_det,
               'EXAM.CODE_EXAM.' || ea.id_exam code_exam,
               ea.flg_status_det flg_status,
               ea.id_patient,
               nvl(ea.id_episode, ea.id_episode_origin) id_episode,
               ea.dt_begin dt_begin_tstz,
               ea.dt_req dt_req_tstz,
               ea.priority,
               ea.status_str_req,
               ea.status_msg_req,
               ea.status_icon_req,
               ea.status_flg_req,
               ea.id_task_dependency,
               ea.flg_req_origin_module
          FROM exams_ea ea
         WHERE ea.flg_type = decode(sys_context('ALERT_CONTEXT', 'i_prof_software'),
                                    sys_context('ALERT_CONTEXT', 'exams_software'),
                                    'E',
                                    sys_context('ALERT_CONTEXT', 'itech_software'),
                                    'I')
           AND ((sys_context('ALERT_CONTEXT', 'l_search_concluded') = 'N' AND ea.flg_status_det NOT IN ('DF', 'C', 'NR')) OR
               sys_context('ALERT_CONTEXT', 'l_search_concluded') = 'Y')) er
 WHERE (EXISTS (SELECT 1
                  FROM institution i
                 WHERE i.id_parent =
                       (SELECT i.id_parent
                          FROM institution i
                         WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                   AND i.id_institution = v.id_institution) OR
        v.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
   AND v.flg_status_e IN ('A', 'P')
   AND v.id_patient = pat.id_patient
   AND v.flg_ehr = 'N'
   AND v.id_patient = er.id_patient
   AND v.id_episode = er.id_episode
   AND er.id_exam_req_det = er2.id_exam_req_det
   AND dcs.id_dep_clin_serv(+) = v.id_dep_clin_serv;
/