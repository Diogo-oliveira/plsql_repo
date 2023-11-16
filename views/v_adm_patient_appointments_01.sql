CREATE OR REPLACE VIEW V_ADM_PATIENT_APPOINTMENTS_01 AS
SELECT t.sel_type,
       t.sel_sub_type,
       t.event_type,
       t.id_event_type,
       t.id_patient,
       t.age,
       t.num_clin_record,
       t.id_episode,
       t.id_dept,
       t.id_clinical_service,
       t.id_professional,
       t.id_exam_cat,
       t.id_exam,
       t.dt_schedule_tstz,
       t.notes,
       t.dt_begin_tstz,
       t.id_exam_req,
       t.id_exam_req_det,
       t.flg_status_req_det,
       t.dt_req_tstz,
       t.id_prof_req,
       t.id_institution,
       t.id_schedule,
       t.flg_req_origin_module,
       t.gender,
       t.name,
       t.id_room,
       t.comb_name,
       t.id_external_request,
       t.id_workflow,
       t.flg_type,
       t.flg_status,
       t.id_speciality,
       t.id_inst_orig,
       t.id_inst_dest,
       t.id_dep_clin_serv,
       t.decision_urg_level,
       t.id_prof_redirected,
       t.id_prof_status,
       t.id_external_sys,
       t.dt_status_tstz,
       t.id_consult_req,
       t.id_instit_requests,
       t.dt_last_update,
       t.dt_consult_req_tstz,
       t.id_reason,
       t.flg_reason_type,
       t.id_prof_dest,
       t.dt_scheduled_tstz,
       t.dt_begin_event,
       t.status_str,
       t.status_msg,
       t.status_icon,
       t.status_flg,
       t.epis_id_dep_clin_serv,
       t.id_epis_type,
       t.id_epis_type_so,
       t.reason_for_visit,
       t.id_sch_event,
       t.dt_end_event,
       t.id_inst_requested,
       t.flg_contact_type,
       t.flg_type_of_external_resource,
       t.id_prof_requested,
       t.reason_visit,
       t.id_prof_orig,
       ce.id_combination_events,
       ce.rank,
       cs.dt_suggest_begin,
       cs.flg_single_visit,
       ce.id_combination_spec,
       0 comb_count,
       nvl2(ce.id_combination_spec,
            (SELECT pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                cs.dt_suggest_begin,
                                                profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_software')))
               FROM dual),
            (SELECT CASE
                        WHEN t.sel_type IN ('I', 'E') THEN
                         (SELECT pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             nvl(t.dt_begin_tstz, t.dt_schedule_tstz),
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_software')))
                            FROM dual)
                        WHEN t.sel_type IN ('R') THEN
                         NULL
                        ELSE
                         (SELECT pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                   t.id_instit_requests,
                                                                                                                   NULL),
                                                                                                      nvl(t.dt_last_update,
                                                                                                          t.dt_consult_req_tstz))
                                                                FROM dual),
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                          sys_context('ALERT_CONTEXT', 'i_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_software')))
                            FROM dual)
                    END
               FROM dual)) order_date
  FROM v_adm_patient_appointments_00 t
  LEFT JOIN combination_events ce
    ON t.id_event_type = ce.id_future_event_type
   AND ce.id_event = t.id_event
   AND ce.flg_status = 'A'
   AND ce.id_future_event_type NOT IN ( /*24,*/ 4, 5)
  LEFT JOIN combination_spec cs
    ON ce.id_combination_spec = cs.id_combination_spec
   AND cs.flg_status = 'A';