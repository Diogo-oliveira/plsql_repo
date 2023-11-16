CREATE OR REPLACE VIEW V_INTERV_SCHEDULED AS
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
/*       substr(concatenate_clob(id_interv_prescription || ';'),
              1,
              length(concatenate_clob(id_interv_prescription || ';')) - 1) id_req,*/
       listagg(id_interv_prescription, ';') id_req,
       listagg(id_interv_presc_det, ';') id_req_det,
       dt_begin_tstz,
       id_room,
       MAX(flg_status_req_det) flg_status_req_det,
       id_task_dependency,
       NULL flg_req_origin_module,
       id_episode g_episode,
       NULL s_flg_status,
       flg_ehr,
       s_id_dcs_requested,
       'InterventionsIcon' type_icon
  FROM (SELECT DISTINCT ip.id_patient,
                        pk_patient.get_gender(sys_context('ALERT_CONTEXT', 'i_lang'), p.gender) gender,
                        to_char(p.age) pat_age,
                        (SELECT cr.num_clin_record
                           FROM clin_record cr
                          WHERE cr.id_patient = ip.id_patient
                            AND cr.id_institution = ip.id_institution
                            AND cr.id_instit_enroled = ip.id_institution
                            AND cr.flg_status = 'A'
                            AND cr.num_clin_record IS NOT NULL) num_clin_record,
                        NULL id_schedule,
                        NULL no_show,
                        ip.id_episode,
                        e.flg_status flg_status_epis,
                        ip.id_institution,
                        (SELECT dept.id_dept
                           FROM epis_info ei, clinical_service cs, dept dept, episode epis_origin
                          WHERE epis_origin.id_episode = ip.id_episode_origin
                            AND ei.id_episode = epis_origin.id_episode
                            AND cs.id_clinical_service = epis_origin.id_clinical_service
                            AND ei.id_dep_clin_serv IS NOT NULL
                            AND dept.id_dept = epis_origin.id_dept
                            AND dept.id_institution = ip.id_institution
                         UNION
                         SELECT dept.id_dept
                           FROM epis_info ei, clinical_service cs, dept dept, episode epis_origin
                          WHERE epis_origin.id_episode = ip.id_episode_origin
                            AND ei.id_episode = epis_origin.id_episode
                            AND cs.id_clinical_service = decode(epis_origin.id_clinical_service,
                                                                -1,
                                                                epis_origin.id_cs_requested,
                                                                epis_origin.id_clinical_service)
                            AND ei.id_dep_clin_serv IS NULL
                            AND dept.id_dept = epis_origin.id_dept_requested
                            AND dept.id_institution = ip.id_institution
                         UNION
                         SELECT dept.id_dept
                           FROM epis_info ei, department d, dept dept, room r, episode epis_origin
                          WHERE epis_origin.id_episode = ip.id_episode_origin
                            AND ei.id_episode = epis_origin.id_episode
                            AND ei.id_dep_clin_serv IS NULL
                            AND ei.id_room = r.id_room
                            AND r.id_department = d.id_department
                            AND d.id_dept = dept.id_dept) id_dept,
                        (SELECT cs.id_clinical_service
                           FROM epis_info ei, clinical_service cs, dept dept, episode epis_origin
                          WHERE epis_origin.id_episode = ip.id_episode_origin
                            AND ei.id_episode = epis_origin.id_episode
                            AND cs.id_clinical_service = epis_origin.id_clinical_service
                            AND ei.id_dep_clin_serv IS NOT NULL
                            AND dept.id_dept = epis_origin.id_dept
                            AND dept.id_institution = ip.id_institution
                         UNION
                         SELECT cs.id_clinical_service
                           FROM epis_info ei, clinical_service cs, dept dept, episode epis_origin
                          WHERE epis_origin.id_episode = ip.id_episode_origin
                            AND ei.id_episode = epis_origin.id_episode
                            AND cs.id_clinical_service = decode(epis_origin.id_clinical_service,
                                                                -1,
                                                                epis_origin.id_cs_requested,
                                                                epis_origin.id_clinical_service)
                            AND ei.id_dep_clin_serv IS NULL
                            AND dept.id_dept = epis_origin.id_dept_requested
                            AND dept.id_institution = ip.id_institution) id_clinical_service,
                        'I' flg_type,
                        ipd.id_intervention,
                        ip.id_interv_prescription,
                        ipd.id_interv_presc_det,
                        nvl(ipp.dt_plan_tstz, ipd.dt_begin_tstz) dt_begin_tstz,
                        ei.id_room,
                        decode(ipd.flg_status, 'D', ipd.flg_status, nvl(ipp.flg_status, ipd.flg_status)) flg_status_req_det,
                        NULL id_task_dependency,
                        NULL flg_req_origin_module,
                        e.flg_ehr,
                        NULL s_id_dcs_requested
          FROM interv_prescription ip, interv_presc_det ipd, interv_presc_plan ipp, episode e, epis_info ei, patient p
         WHERE ip.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND ((ip.flg_time = 'B' AND ipp.id_wound_treat IS NULL) OR
               (ip.flg_time = 'E' AND (ip.id_episode IS NULL OR e.id_epis_type = 24)))
           AND ip.id_interv_prescription = ipd.id_interv_prescription
           AND ipd.flg_status != 'X'
           AND ipd.id_interv_presc_det = ipp.id_interv_presc_det
           AND ip.id_episode = e.id_episode(+)
           AND e.id_episode = ei.id_episode(+)
           AND ip.id_patient = p.id_patient
           AND sys_context('ALERT_CONTEXT', 'i_prof_software') IN (1, 12, 39))
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
          flg_ehr,
          s_id_dcs_requested;