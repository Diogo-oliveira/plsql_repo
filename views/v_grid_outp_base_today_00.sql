CREATE OR REPLACE VIEW v_grid_outp_base_today_00 AS
SELECT view_type,
       flg_group_header,
       cmpt_code_complaint,
       e_id_department,
       e_id_visit,
       e_flg_ehr,
       e_dt_begin_tstz,
       e_flg_status,
       ec_id_complaint,
       ec_patient_complaint,
       ei_id_episode,
       ei_id_software,
       ei_id_professional,
       ei_id_first_nurse_resp,
       ei_id_room,
       ei_id_dep_clin_serv,
       gt_id_episode,
       gt_drug_presc,
       gt_icnp_intervention,
       gt_nurse_activity,
       gt_intervention,
       gt_monitorization,
       gt_teach_req,
       pat_gender,
       ps_nick_name,
       ps_name,
       ei_nick_name,
       ei_name,
       ps_id_professional,
       s_id_schedule,
       s_id_group,
       s_flg_present,
       s_id_dcs_requested,
       s_id_sch_event,
       s_id_instit_requested,
       s_flg_status,
       se_code_sch_event,
       se_flg_is_group,
       sg_flg_contact_type,
       sp_dt_target_tstz,
       sp_id_epis_type,
       sp_flg_state,
       sp_flg_sched,
       sp_id_software,
       se_id_sch_event,
       sg_id_patient,
       nvl(flg_leader, 'Y') flg_leader,
       e_id_epis_type,
       NULL sys_dt_min,
       NULL sys_dt_max,
       alert_context('g_epis_type_nurse') sys_epis_type_nurse,
       alert_context('g_sched_adm_disch') sys_sched_adm_disch,
       alert_context('g_sched_canc') sys_sched_canc,
       alert_context('g_sched_status_cache') sys_sched_status_cache,
       alert_context('g_selected') sys_selected,
       'N' sys_no,
       'Y' sys_yes,
       alert_context('i_institution') sys_institution,
       alert_context('i_lang') sys_lang,
       alert_context('i_software') sys_software,
       alert_context('i_prof_id') sys_prof_id,
       profissional(alert_context('i_prof_id'), alert_context('i_institution'), alert_context('i_software')) sys_lprof
  FROM (SELECT /*+ index(sp SOP_DTTARGETTSTZ_I) */
         '05_SINGLE_ROW' view_type,
         'N' flg_group_header,
         NULL cmpt_code_complaint,
         e.id_department e_id_department,
         e.id_visit e_id_visit,
         e.flg_ehr e_flg_ehr,
         e.dt_begin_tstz e_dt_begin_tstz,
         e.flg_status e_flg_status,
         NULL ec_id_complaint,
         NULL ec_patient_complaint,
         ei.id_episode ei_id_episode,
         ei.id_software ei_id_software,
         ei.id_professional ei_id_professional,
         ei.id_first_nurse_resp ei_id_first_nurse_resp,
         ei.id_room ei_id_room,
         ei.id_dep_clin_serv ei_id_dep_clin_serv,
         gt.id_episode gt_id_episode,
         gt.drug_presc gt_drug_presc,
         gt.icnp_intervention gt_icnp_intervention,
         gt.nurse_activity gt_nurse_activity,
         gt.intervention gt_intervention,
         gt.monitorization gt_monitorization,
         gt.teach_req gt_teach_req,
         pat.gender pat_gender,
         prof_ps.nick_name ps_nick_name,
         prof_ps.name ps_name,
         prof_ei.nick_name ei_nick_name,
         prof_ei.name ei_name,
         ps.id_professional ps_id_professional,
         s.id_schedule s_id_schedule,
         s.id_group s_id_group,
         s.flg_present s_flg_present,
         s.id_dcs_requested s_id_dcs_requested,
         s.id_sch_event s_id_sch_event,
         s.id_instit_requested s_id_instit_requested,
         s.flg_status s_flg_status,
         se.code_sch_event se_code_sch_event,
         se.flg_is_group se_flg_is_group,
         sg.flg_contact_type sg_flg_contact_type,
         sp.dt_target_tstz sp_dt_target_tstz,
         sp.id_epis_type sp_id_epis_type,
         sp.flg_state sp_flg_state,
         sp.flg_sched sp_flg_sched,
         sp.id_software sp_id_software,
         se.id_sch_event se_id_sch_event,
         sg.id_patient sg_id_patient,
         nvl(ps.flg_leader, 'Y') flg_leader,
         e.id_epis_type e_id_epis_type
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          LEFT JOIN sch_resource ps
            ON ps.id_schedule = sp.id_schedule
          JOIN patient pat
            ON pat.id_patient = sg.id_patient
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
          LEFT JOIN grid_task gt
            ON gt.id_episode = ei.id_episode
          LEFT JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          LEFT JOIN professional prof_ps
            ON prof_ps.id_professional = ps.id_professional
          LEFT JOIN professional prof_ei
            ON prof_ei.id_professional = ei.id_professional
         WHERE sp.dt_target_tstz BETWEEN CAST((SELECT pk_date_utils.get_string_tstz(alert_context('i_lang'),
                                                                                    profissional(alert_context('i_prof_id'),
                                                                                                 alert_context('i_institution'),
                                                                                                 alert_context('i_software')),
                                                                                    alert_context('i_dt'),
                                                                                    '')
                                                 FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE) AND
               CAST((SELECT pk_date_utils.add_to_ltstz(pk_date_utils.add_days(alert_context('i_lang'),
                                                                              profissional(alert_context('i_prof_id'),
                                                                                           alert_context('i_institution'),
                                                                                           alert_context('i_software')),
                                                                              pk_date_utils.get_string_tstz(alert_context('i_lang'),
                                                                                                            profissional(alert_context('i_prof_id'),
                                                                                                                         alert_context('i_institution'),
                                                                                                                         alert_context('i_software')),
                                                                                                            alert_context('i_dt'),
                                                                                                            ''),
                                                                              alert_context('AMOUNT')),
                                                       -1,
                                                       'SECOND')
                       FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE)
        UNION ALL
        SELECT '00_GROUP_ROW' view_type,
               'Y' flg_group_header,
               'NULL' cmpt_code_complaint,
               e.id_department e_id_department,
               e.id_visit e_id_visit,
               e.flg_ehr e_flg_ehr,
               e.dt_begin_tstz e_dt_begin_tstz,
               e.flg_status e_flg_status,
               NULL ec_id_complaint,
               NULL ec_patient_complaint,
               ei.id_episode ei_id_episode,
               ei.id_software ei_id_software,
               ei.id_professional ei_id_professional,
               ei.id_first_nurse_resp ei_id_first_nurse_resp,
               ei.id_room ei_id_room,
               ei.id_dep_clin_serv ei_id_dep_clin_serv,
               gt.id_episode gt_id_episode,
               gt.drug_presc gt_drug_presc,
               gt.icnp_intervention gt_icnp_intervention,
               gt.nurse_activity gt_nurse_activity,
               gt.intervention gt_intervention,
               gt.monitorization gt_monitorization,
               gt.teach_req gt_teach_req,
               'NULL' pat_gender,
               prof_ps.nick_name ps_nick_name,
               prof_ps.name ps_name,
               prof_ei.nick_name ei_nick_name,
               prof_ei.name ei_name,
               ps.id_professional ps_id_professional,
               s.id_schedule s_id_schedule,
               s.id_group s_id_group,
               s.flg_present s_flg_present,
               s.id_dcs_requested s_id_dcs_requested,
               s.id_sch_event s_id_sch_event,
               s.id_instit_requested s_id_instit_requested,
               s.flg_status s_flg_status,
               se.code_sch_event se_code_sch_event,
               se.flg_is_group se_flg_is_group,
               sg.flg_contact_type sg_flg_contact_type,
               sp.dt_target_tstz sp_dt_target_tstz,
               sp.id_epis_type sp_id_epis_type,
               sp.flg_state sp_flg_state,
               sp.flg_sched sp_flg_sched,
               sp.id_software sp_id_software,
               se.id_sch_event se_id_sch_event,
               sg.id_patient sg_id_patient,
               'Y' flg_leader,
               e.id_epis_type e_id_epis_type
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          LEFT JOIN sch_prof_outp ps
            ON ps.id_schedule_outp = sp.id_schedule_outp
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
          LEFT JOIN grid_task gt
            ON gt.id_episode = ei.id_episode
          LEFT JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          LEFT JOIN professional prof_ps
            ON prof_ps.id_professional = ps.id_professional
          LEFT JOIN professional prof_ei
            ON prof_ei.id_professional = ei.id_professional
          JOIN (SELECT id_group, id_schedule
                 FROM (SELECT t.*
                         FROM (SELECT s.id_group,
                                      s.id_schedule,
                                      s.id_sch_event,
                                      row_number() over(PARTITION BY s.id_group ORDER BY s.id_schedule) rn
                                 FROM schedule_outp sp
                                 JOIN schedule s
                                   ON s.id_schedule = sp.id_schedule
                                WHERE s.flg_status NOT IN ('C', 'D')
                                  AND s.id_group IS NOT NULL
                                  AND s.id_instit_requested = alert_context('i_institution')
                                  AND sp.dt_target_tstz BETWEEN
                                      CAST((SELECT pk_date_utils.get_string_tstz(alert_context('i_lang'),
                                                                                 profissional(alert_context('i_prof_id'),
                                                                                              alert_context('i_institution'),
                                                                                              alert_context('i_software')),
                                                                                 alert_context('i_dt'),
                                                                                 '')
                                              FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                                      CAST((SELECT pk_date_utils.add_to_ltstz(pk_date_utils.add_days(alert_context('i_lang'),
                                                                                                     profissional(alert_context('i_prof_id'),
                                                                                                                  alert_context('i_institution'),
                                                                                                                  alert_context('i_software')),
                                                                                                     pk_date_utils.get_string_tstz(alert_context('i_lang'),
                                                                                                                                   profissional(alert_context('i_prof_id'),
                                                                                                                                                alert_context('i_institution'),
                                                                                                                                                alert_context('i_software')),
                                                                                                                                   alert_context('i_dt'),
                                                                                                                                   ''),
                                                                                                     alert_context('AMOUNT')),
                                                                              -1,
                                                                              'SECOND')
                                              FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE)
                                  AND rownum > 0) t
                         JOIN sch_event se
                           ON se.id_sch_event = t.id_sch_event
                        WHERE se.flg_is_group = 'Y') xsql
                WHERE rn = 1) scg
            ON scg.id_schedule = s.id_schedule
           AND scg.id_group = s.id_group);
