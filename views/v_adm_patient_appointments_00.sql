CREATE OR REPLACE VIEW V_ADM_PATIENT_APPOINTMENTS_00 AS
SELECT 'C' sel_type,
       'C1' sel_sub_type,
       'FUTURE_EVENTS' event_type,
       fet.id_future_event_type id_event_type,
       cr.id_patient,
       pt.age,
       NULL num_clin_record,
       cr.id_episode,
       NULL id_dept,
       NULL id_clinical_service,
       NULL id_professional,
       NULL id_exam_cat,
       NULL id_exam,
       NULL dt_schedule_tstz,
       cr.notes,
       NULL dt_begin_tstz,
       NULL id_exam_req,
       NULL id_exam_req_det,
       NULL flg_status_req_det,
       NULL dt_req_tstz,
       cr.id_prof_req,
       NULL id_institution,
       NULL id_schedule,
       NULL flg_req_origin_module,
       pt.gender,
       pt.name,
       NULL id_room,
       NULL comb_name,
       NULL id_external_request,
       NULL id_workflow,
       NULL flg_type,
       cr.flg_status,
       NULL id_speciality,
       NULL id_inst_orig,
       NULL id_inst_dest,
       cr.id_dep_clin_serv,
       NULL decision_urg_level,
       NULL id_prof_redirected,
       NULL id_prof_status,
       NULL id_external_sys,
       NULL dt_status_tstz,
       cr.id_consult_req,
       cr.id_instit_requests,
       cr.dt_last_update,
       cr.dt_consult_req_tstz,
       NULL id_reason,
       NULL flg_reason_type,
       NULL id_prof_dest,
       cr.dt_scheduled_tstz,
       cr.dt_begin_event,
       cr.status_str,
       cr.status_msg,
       cr.status_icon,
       cr.status_flg,
       cr.id_dep_clin_serv epis_id_dep_clin_serv,
       cr.id_epis_type,
       cr.reason_for_visit,
       NULL id_sch_event,
       cr.dt_end_event,
       cr.id_inst_requested,
       cr.flg_contact_type,
       'H' flg_type_of_external_resource,
       cr.id_prof_requested,
       cr.id_complaint reason_visit,
       cr.id_prof_req id_prof_orig,
       null id_epis_type_so,
       cr.id_consult_req id_event
  FROM consult_req cr
  JOIN patient pt
    ON pt.id_patient = cr.id_patient
  LEFT JOIN future_event_type fet
    ON fet.id_epis_type = cr.id_epis_type
 WHERE (cr.id_schedule IS NULL OR EXISTS (SELECT 0
                                            FROM schedule s
                                           WHERE s.id_schedule = cr.id_schedule
                                             AND s.flg_status = 'C'))
   AND (cr.id_dep_clin_serv IS NULL OR EXISTS (SELECT 0
                                                 FROM prof_dep_clin_serv pdcs
                                                WHERE pdcs.id_dep_clin_serv = cr.id_dep_clin_serv
                                                  AND pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                                                  AND pdcs.flg_status = 'S'))
   AND cr.id_inst_requested = sys_context('ALERT_CONTEXT', 'i_institution')
   AND cr.flg_status IN ('P', 'C', 'H')
   AND ( sys_context('ALERT_CONTEXT', 'l_category') = 'A' OR
        EXISTS
        (SELECT 0
           FROM sch_permission sp
          WHERE sp.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
            AND sp.id_dep_clin_serv = cr.id_dep_clin_serv
            AND sp.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
            AND (sp.id_prof_agenda = cr.id_prof_requested OR cr.id_prof_requested IS NULL)
            AND (sp.flg_permission = 'S')))
   AND ((cr.flg_status != 'C') OR
       (cr.flg_status = 'C' AND trunc(cr.dt_cancel_tstz, 'DD') >= trunc(current_timestamp, 'DD')))

UNION ALL

SELECT 'C' sel_type,
       'C2' sel_sub_type,
       'FUTURE_EVENTS' event_type,
       fet.id_future_event_type id_event_type,
       sg.id_patient,
       pt.age,
       NULL num_clin_record,
       cr.id_episode,
       NULL id_dept,
       NULL id_clinical_service,
       sr.id_professional,
       NULL id_exam_cat,
       NULL id_exam,
       s.dt_schedule_tstz,
       cr.notes,
       s.dt_begin_tstz,
       NULL id_exam_req,
       NULL id_exam_req_det,
       NULL flg_status_req_det,
       NULL dt_req_tstz,
       cr.id_prof_req,
       NULL id_institution,
       s.id_schedule,
       NULL flg_req_origin_module,
       pt.gender,
       pt.name,
       NULL id_room,
       NULL comb_name,
       NULL id_external_request,
       NULL id_workflow,
       NULL flg_type,
       cr.flg_status flg_status,
       NULL id_speciality,
       NULL id_inst_orig,
       NULL id_inst_dest,
       s.id_dcs_requested id_dep_clin_serv,
       NULL decision_urg_level,
       NULL id_prof_redirected,
       NULL id_prof_status,
       NULL id_external_sys,
       NULL dt_status_tstz,
       cr.id_consult_req,
       cr.id_instit_requests,
       cr.dt_last_update,
       cr.dt_consult_req_tstz,
       s.id_reason,
       s.flg_reason_type,
       ei.sch_prof_outp_id_prof id_prof_dest,
       cr.dt_scheduled_tstz,
       cr.dt_begin_event,
       cr.status_str,
       cr.status_msg,
       cr.status_icon,
       cr.status_flg,
       ei.id_dep_clin_serv epis_id_dep_clin_serv,
       cr.id_epis_type,
       cr.reason_for_visit,
       s.id_sch_event,
       cr.dt_end_event,
       cr.id_inst_requested,
       sg.flg_contact_type,
       NULL flg_type_of_external_resource,
       cr.id_prof_requested,
       decode(s.flg_reason_type, 'C', s.id_reason, NULL) reason_visit,
       cr.id_prof_req id_prof_orig,
       so.id_epis_type id_epis_type_so,
       cr.id_consult_req id_event
  FROM schedule s
  JOIN sch_group sg
    ON (sg.id_schedule = s.id_schedule)
  JOIN patient pt
    ON (pt.id_patient = sg.id_patient)
  JOIN consult_req cr
    ON (cr.id_schedule = s.id_schedule)
  JOIN epis_info ei
    ON (ei.id_episode = cr.id_episode)
  JOIN schedule_outp so
    ON (so.id_schedule = s.id_schedule)
  LEFT JOIN sch_resource sr
    ON (sr.id_schedule = s.id_schedule)
  LEFT JOIN future_event_type fet
    ON fet.id_epis_type = so.id_epis_type
 WHERE s.id_instit_requested = sys_context('ALERT_CONTEXT', 'i_institution')
   AND s.id_dcs_requested IN (SELECT pdcs.id_dep_clin_serv
                                FROM prof_dep_clin_serv pdcs
                               WHERE pdcs.id_dep_clin_serv = s.id_dcs_requested
                                 AND pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                                 AND pdcs.flg_status = 'S')
   AND s.flg_status = 'A'
   AND s.dt_begin_tstz >=
       (SELECT pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                             sys_context('ALERT_CONTEXT', 'i_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_software')),
                                                current_timestamp)
          FROM dual)
   AND s.flg_sch_type = 'C'
   AND cr.flg_status NOT IN ('S')
   AND EXISTS
 (SELECT 0
          FROM sch_permission sp
         WHERE sp.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND (sp.id_prof_agenda = sr.id_professional OR sr.id_professional IS NULL OR sp.id_professional IS NULL)
           AND (sp.id_dep_clin_serv = s.id_dcs_requested OR sp.id_dep_clin_serv IS NULL)
           AND (sp.flg_permission = 'S')
           AND (sp.id_sch_event = s.id_sch_event))
   AND trunc(s.dt_schedule_tstz, 'DD') >= trunc(current_timestamp, 'DD')
 AND (((so.id_epis_type =  sys_context('ALERT_CONTEXT', 'g_epis_type') ) AND sys_context('ALERT_CONTEXT', 'l_category') = 'N') OR
sys_context('ALERT_CONTEXT', 'l_category') != 'N')

UNION ALL

SELECT 'R' sel_type,
       NULL sel_sub_type,
       'REFERRAL' event_type,
       24 id_event_type,
       p.id_patient,
       pt.age,
       cr.num_clin_record,
       p.id_episode,
       NULL id_dept,
       NULL id_clinical_service,
       NULL id_professional,
       NULL id_exam_cat,
       NULL id_exam,
       NULL dt_schedule_tstz,
       NULL notes,
       NULL dt_begin_tstz,
       NULL id_exam_req,
       NULL id_exam_req_det,
       NULL flg_status_req_det,
       NULL dt_req_tstz,
       p.id_prof_requested id_prof_req,
       NULL id_institution,
       NULL id_schedule,
       NULL flg_req_origin_module,
       pt.gender,
       pt.name,
       NULL id_room,
       NULL comb_name,
       p.id_external_request,
       p.id_workflow,
       p.flg_type,
       p.flg_status,
       p.id_speciality,
       p.id_inst_orig,
       p.id_inst_dest,
       p.id_dep_clin_serv,
       p.decision_urg_level,
       p.id_prof_redirected,
       p.id_prof_status,
       p.id_external_sys,
       p.dt_status_tstz,
       NULL id_consult_req,
       NULL id_instit_requests,
       NULL dt_last_update,
       NULL dt_consult_req_tstz,
       NULL id_reason,
       NULL flg_reason_type,
       NULL id_prof_dest,
       NULL dt_scheduled_tstz,
       NULL dt_begin_event,
       NULL status_str,
       NULL status_msg,
       NULL status_icon,
       NULL status_flg,
       NULL epis_id_dep_clin_serv,
       NULL id_epis_type,
       NULL reason_for_visit,
       NULL id_sch_event,
       NULL dt_end_event,
       NULL id_inst_requested,
       p.flg_type flg_contact_type,
       NULL flg_type_of_external_resource,
       p.id_prof_requested id_prof_requested,
       NULL reason_visit,
       p.id_prof_requested id_prof_orig,
       null id_epis_type_so,
       p.id_external_request id_event
  FROM p1_external_request p
  JOIN patient pt
    ON (pt.id_patient = p.id_patient)
  LEFT JOIN clin_record cr
    ON (pt.id_patient = cr.id_patient AND cr.flg_status = 'A' AND cr.id_institution = p.id_inst_dest AND
       cr.id_instit_enroled = cr.id_institution)
 WHERE p.flg_status = 'A'
   AND EXISTS (SELECT 1
          FROM prof_dep_clin_serv pdcs
         WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
           AND pdcs.flg_status = 'S'
           AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')
           AND pdcs.id_dep_clin_serv = p.id_dep_clin_serv)
   AND p.id_inst_dest = sys_context('ALERT_CONTEXT', 'i_institution');
