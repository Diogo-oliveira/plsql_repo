CREATE OR REPLACE VIEW V_TECH_LABS_GRID AS
SELECT DISTINCT gtl.id_patient,
                                    gtl.id_harvest,
                                    gtl.id_episode,
                                    gtl.id_epis_type,
                                    gtl.acuity,
                                    gtl.rank_acuity,
                                    gtl.triage_color_text,
                                    gtl.id_triage_color,
                                    gtl.dt_first_obs_tstz,
                                    gtl.id_software,
                                    gtl.id_institution,
                                    gtl.id_sample_recipient,
                                    gtl.request,
                                    gtl.harvest,
                                    gtl.transport,
                                    gtl.execute,
                                    gtl.complete,
                                    gtl.id_announced_arrival,
                                    gtl.flg_status_ard,
                                    gtl.dt_pend_req_tstz,
                                    gtl.dt_target_tstz,
                                    gtl.dt_req_tstz,
                                    gtl.dt_order,
                                    CASE WHEN gtl.flg_status_ard in ('R','D') THEN
                                        coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)
                                       ELSE
                                         NULL
                                       END dt_request,
                                    CASE WHEN gtl.flg_status_ard = 'E' THEN
                                       coalesce(h.dt_harvest_tstz ,gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)
                                       ELSE
                                         NULL
                                       END dt_harvest,
                                    CASE WHEN h.flg_status = 'H' THEN
                                           h.dt_harvest_tstz
                                       ELSE
                                         NULL
                                       END dt_collected,
                                    CASE WHEN h.flg_status = 'T' THEN
                                           coalesce(m.dt_begin_tstz, h.dt_mov_begin_tstz, h.dt_harvest_tstz)
                                       ELSE
                                         NULL
                                       END dt_transp,
																		CASE WHEN h.Flg_Status = 'F' THEN
                                           coalesce(m.dt_end_tstz, h.dt_lab_reception_tstz, h.dt_harvest_tstz)
                                       ELSE
                                         NULL
                                       END dt_execute,
                                    CASE WHEN ard.flg_status in ('R', 'L')
                                    THEN
                                      ard.dt_target_tstz
                                    ELSE
                                     NULL
                                    END dt_complete,
                decode(gtl.flg_status_ard,
                       'R',
                       (SELECT pk_sysdomain.get_domain(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                       'ANALYSIS_REQ_DET.FLG_STATUS',
                                                       gtl.flg_status_ard,
                                                       NULL)
                          FROM dual),
                       'D',
                       (SELECT pk_sysdomain.get_domain(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                       'ANALYSIS_REQ_DET.FLG_STATUS',
                                                       gtl.flg_status_ard,
                                                       NULL)
                          FROM dual),
                       (SELECT pk_sysdomain.get_domain(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                       'ANALYSIS_REQ_DET.FLG_STATUS',
                                                       gtl.flg_status_ard,
                                                       NULL)
                          FROM dual)) rank
                      FROM grid_task_lab gtl
                        INNER JOIN analysis_req_det ard ON ard.id_analysis_req_det = gtl.id_analysis_req_det
                        LEFT JOIN movement m ON m.id_movement = ard.id_movement
                        LEFT JOIN harvest h on h.id_harvest = gtl.id_harvest
                     WHERE (EXISTS
                            (SELECT 1
                               FROM institution i
                              WHERE i.id_parent = (SELECT i.id_parent
                                                     FROM institution i
                                                    WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                                AND i.id_institution = gtl.id_institution) OR gtl.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                       AND ((gtl.flg_time_harvest = 'E' AND
                           gtl.flg_status_epis = 'A' AND
                           ((gtl.flg_status_ard IN ('R',
                                                      'CC',
                                                      'E',
                                                      'F')) OR
                           (gtl.flg_status_ard IN ('R',
                                                      'D',
                                                      'CC',
                                                      'E',
                                                      'F') AND
                           nvl(sys_context('ALERT_CONTEXT', 'l_collect_pending'), 'Y') = 'Y'))) OR
                           (gtl.flg_time_harvest IN ('B', 'D') AND
                           nvl(gtl.dt_target_tstz, gtl.dt_order) BETWEEN sys_context('ALERT_CONTEXT', 'i_dt_begin') AND sys_context('ALERT_CONTEXT', 'i_dt_end') AND
                           gtl.flg_status_ard NOT IN
                           ('PA', 'A')) OR
                           (gtl.flg_time_harvest = 'N' AND
                           gtl.flg_status_epis = 'A' AND
                           ((gtl.flg_status_ard IN ('R',
                                                      'CC',
                                                      'E',
                                                      'F')) OR
                           (gtl.flg_status_ard IN ('R',
                                                      'D',
                                                      'CC',
                                                      'E',
                                                      'F') AND
                           nvl(sys_context('ALERT_CONTEXT', 'l_collect_pending'), 'Y') = 'Y'))))
                      AND EXISTS
                     (SELECT 1
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
                       AND gtl.id_announced_arrival IS NOT NULL
                    UNION ALL
                    SELECT DISTINCT s.id_patient,
                                    gtl.id_harvest,
                                    ei.id_episode,
                                    12 id_epis_type,
                                    NULL                              acuity,
                                    NULL                              rank_acuity,
                                    NULL                              triage_color_text,
                                    NULL                              id_triage_color,
                                    NULL                              dt_first_obs_tstz,
                                    16  id_software,
                                    s.id_inst_requests                id_institution,
                                    gtl.id_sample_recipient,
                                    gtl.request                       col_request,
                                    gtl.harvest                       col_harvest,
                                    gtl.transport                     col_transport,
                                    gtl.execute                       col_execute,
                                    gtl.complete                      col_complete,
                                    NULL                              id_announced_arrival,
                                    NULL                              flg_status_ard,
                                    NULL                              dt_pend_req_tstz,
                                    s.dt_begin                        dt_target_tstz,
                                    NULL                              dt_req_tstz,
                                    NULL                              dt_order,
                                    CASE WHEN gtl.flg_status_ard in ('R','D') THEN
                                        coalesce(gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)
                                       ELSE
                                         NULL
                                       END dt_request,
                                    CASE WHEN gtl.flg_status_ard = 'E' THEN
                                       coalesce(h.dt_harvest_tstz ,gtl.dt_pend_req_tstz, gtl.dt_target_tstz, gtl.dt_req_tstz)
                                       ELSE
                                         NULL
                                       END dt_harvest,
                                    CASE WHEN h.flg_status = 'H' THEN
                                           h.dt_harvest_tstz
                                       ELSE
                                         NULL
                                       END dt_collected,
                                    CASE WHEN h.flg_status = 'T' THEN
                                           coalesce(m.dt_begin_tstz, h.dt_mov_begin_tstz, h.dt_harvest_tstz)
                                       ELSE
                                         NULL
                                       END dt_transp,
                                    CASE WHEN h.Flg_Status = 'F' THEN
                                           coalesce(m.dt_end_tstz, h.dt_lab_reception_tstz, h.dt_harvest_tstz)
                                       ELSE
                                         NULL
                                       END dt_execute,
																		CASE WHEN ard.flg_status in ('R', 'L')
																		THEN
																		  ard.dt_target_tstz
																		ELSE
																		 NULL
																		END dt_complete,
                decode(gtl.flg_status_ard,
                       'R',
                       (SELECT pk_sysdomain.get_domain(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                       'ANALYSIS_REQ_DET.FLG_STATUS',
                                                       gtl.flg_status_ard,
                                                       NULL)
                          FROM dual),
                       'D',
                       (SELECT pk_sysdomain.get_domain(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                       'ANALYSIS_REQ_DET.FLG_STATUS',
                                                       gtl.flg_status_ard,
                                                       NULL)
                          FROM dual),
                       (SELECT pk_sysdomain.get_domain(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                       profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                    sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                       'ANALYSIS_REQ_DET.FLG_STATUS',
                                                       gtl.flg_status_ard,
                                                       NULL)
                          FROM dual)) rank
                      FROM grid_task_lab gtl,
                           TABLE(pk_schedule_lab.get_today_lab_appoints(sys_context('ALERT_CONTEXT', 'i_lang'), profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'), sys_context('ALERT_CONTEXT', 'i_prof_institution'), sys_context('ALERT_CONTEXT', 'i_prof_software')))) s,
                           epis_info ei,
                           analysis_req_det ard,
                           movement m,
                           harvest h
                     WHERE s.id_analysis_req IS NULL
                       AND s.id_schedule = ei.id_schedule
                       AND ei.id_episode = gtl.id_episode(+)
                       AND gtl.id_analysis_req_det = ard.id_analysis_req_det(+)
                       AND ard.id_movement = m.id_movement(+)
                       AND gtl.id_harvest = h.id_harvest(+);
