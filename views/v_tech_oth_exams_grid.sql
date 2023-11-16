CREATE OR REPLACE VIEW V_TECH_OTH_EXAMS_GRID AS
WITH aux AS
 (SELECT pdcs.id_dep_clin_serv
    FROM prof_dep_clin_serv pdcs
   WHERE pdcs.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
     AND pdcs.flg_status = 'S'
     AND pdcs.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
SELECT gtoe.rank,
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
       gtoe.flg_result,
       decode(eea.id_exam_group, NULL, eea.id_exam, eea.id_exam_group) id_exam,
       decode(eea.id_exam_group, NULL, 'E', 'G') flg_type,
       eea.flg_time,
       eea.dt_req,
       eea.dt_begin,
       eea.dt_pend_req,
       eea.priority,
       eea.flg_notes,
       eea.flg_status_req flg_status, -------------
       eea.status_str_req,
       eea.status_msg_req,
       eea.status_icon_req,
       eea.status_flg_req,
			 eea.status_str,
       eea.status_msg,
       eea.status_icon,
       eea.status_flg,
       so.flg_state,
       gtoe.id_task_dependency,
       gtoe.flg_req_origin_module,
       coalesce(eea.dt_pend_req, eea.dt_req, eea.dt_begin) dt_init,
       coalesce(gtoe.flg_contact, so.flg_state) contact_state_order,
       decode(eea.flg_status_req,
              'R',
              row_number() over(ORDER BY (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                 'EXAM_REQ.FLG_STATUS',
                                                 eea.flg_status_req)
                      FROM dual),
                   coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
              'D',
              row_number() over(ORDER BY (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                 'EXAM_REQ.FLG_STATUS',
                                                 eea.flg_status_req)
                      FROM dual),
                   coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
              row_number() over(ORDER BY (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                 'EXAM_REQ.FLG_STATUS',
                                                 eea.flg_status_req)
                      FROM dual),
                   coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)) rank_ord
  FROM grid_task_oth_exm gtoe
  JOIN exams_ea eea
    ON gtoe.id_exam_req_det = eea.id_exam_req_det
  LEFT JOIN schedule_outp so
    ON gtoe.id_schedule = so.id_schedule
 WHERE (EXISTS (SELECT 1
                  FROM institution i
                 WHERE i.id_parent =
                       (SELECT i.id_parent
                          FROM institution i
                         WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                   AND i.id_institution = gtoe.id_institution) OR
        gtoe.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
   AND ((gtoe.flg_time = 'B' AND gtoe.dt_begin_tstz BETWEEN sys_context('ALERT_CONTEXT', 'i_dt_begin') AND
       sys_context('ALERT_CONTEXT', 'i_dt_end') AND gtoe.flg_status_req_det NOT IN ('A', 'PA')) OR
       (gtoe.flg_time = 'E' AND
       pk_date_utils.trunc_insttimezone(profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                       sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                       sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                          gtoe.dt_begin_tstz) <= sys_context('ALERT_CONTEXT', 'i_date_today') AND
       gtoe.flg_status_epis NOT IN ('I', 'C')) OR
       (gtoe.flg_time = 'N' AND gtoe.id_episode IS NOT NULL AND gtoe.flg_status_req_det != 'D'))
   AND gtoe.flg_status_req_det NOT IN ('X', 'W', 'C')
   AND EXISTS (SELECT 1
          FROM aux a
         WHERE a.id_dep_clin_serv IN (SELECT ecd.id_dep_clin_serv
                                        FROM exam_cat_dcs ecd
                                       WHERE ecd.id_exam_cat = gtoe.id_exam_cat))
   AND instr(nvl((SELECT flg_first_result
                   FROM exam_dep_clin_serv e
                  WHERE e.id_exam = gtoe.id_exam
                    AND e.flg_type = 'P'
                    AND e.id_software = gtoe.id_software
                    AND e.id_institution = gtoe.id_institution),
                 '#'),
             'T') != 0
   AND gtoe.id_announced_arrival IS NOT NULL
;
