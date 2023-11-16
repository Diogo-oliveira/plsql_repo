CREATE OR REPLACE VIEW V_LAB_TEST_ORDER AS
SELECT DISTINCT ar.id_analysis_req,
                (SELECT COUNT(*)
                   FROM lab_tests_ea lte
                   LEFT JOIN (SELECT DISTINCT gar.id_record id_analysis
                               FROM group_access ga
                              INNER JOIN group_access_prof gaf
                                 ON gaf.id_group_access = ga.id_group_access
                              INNER JOIN group_access_record gar
                                 ON gar.id_group_access = ga.id_group_access
                              WHERE ga.id_institution IN (sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                                AND ga.id_software IN (sys_context('ALERT_CONTEXT', 'i_prof_software'))
                                AND ga.flg_type = 'AE'
                                AND gar.flg_type = 'A'
                                AND ga.flg_available = 'Y'
                                AND gaf.flg_available = 'Y'
                                AND gar.flg_available = 'Y') a_infect_i
                     ON lte.id_analysis = a_infect_i.id_analysis
                  WHERE lte.id_analysis_req = ar.id_analysis_req
                    AND (a_infect_i.id_analysis IS NULL OR
                        (a_infect_i.id_analysis = lte.id_analysis AND EXISTS
                         (SELECT 1
                             FROM group_access ga
                            INNER JOIN group_access_prof gaf
                               ON gaf.id_group_access = ga.id_group_access
                            INNER JOIN group_access_record gar
                               ON gar.id_group_access = ga.id_group_access
                            WHERE gaf.id_professional = sys_context('ALERT_CONTEXT', 'i_prof_id')
                              AND ga.id_institution IN (sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                              AND ga.id_software IN (sys_context('ALERT_CONTEXT', 'i_prof_software'))
                              AND ga.flg_type = 'AE'
                              AND gar.flg_type = 'A'
                              AND ga.flg_available = 'Y'
                              AND gaf.flg_available = 'Y'
                              AND gar.flg_available = 'Y')))) id_analysis_req_det,
                ar.flg_status,
                ar.flg_time,
                ar.id_prof_writes,
                ar.dt_req_tstz,
                ar.dt_pend_req_tstz,
                ar.dt_begin_tstz,
                ar.id_episode,
                ar.id_episode_origin,
                e.id_visit,
                ar.id_patient,
                decode(ar.flg_status,
                       'R',
                       dense_rank() over(ORDER BY (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                          'ANALYSIS_REQ.FLG_STATUS',
                                                          ar.flg_status)
                               FROM dual),
                            ar.dt_req_tstz),
                       'D',
                       dense_rank() over(ORDER BY (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                          'ANALYSIS_REQ.FLG_STATUS',
                                                          ar.flg_status)
                               FROM dual),
                            ar.dt_req_tstz),
                       dense_rank() over(ORDER BY (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                          'ANALYSIS_REQ.FLG_STATUS',
                                                          ar.flg_status)
                               FROM dual),
                            ar.dt_req_tstz DESC)) rank
  FROM analysis_req ar, episode e, lab_tests_ea lt
 WHERE ar.id_patient = sys_context('ALERT_CONTEXT', 'i_patient')
   AND ((ar.id_episode = e.id_episode AND ar.id_episode = sys_context('ALERT_CONTEXT', 'i_episode')) OR
       (ar.id_episode_origin = e.id_episode AND ar.id_episode_origin = sys_context('ALERT_CONTEXT', 'i_episode')) OR
       (ar.id_episode = e.id_episode AND nvl(ar.id_episode, 0) != sys_context('ALERT_CONTEXT', 'i_episode') AND
       nvl(ar.id_episode_origin, 0) != sys_context('ALERT_CONTEXT', 'i_episode')))
   AND ar.flg_time != 'R'
   AND EXISTS
 (SELECT 1
          FROM lab_tests_ea lte
         WHERE (lte.flg_orig_analysis IS NULL OR lte.flg_orig_analysis NOT IN ('M', 'O', 'S'))
           AND lte.flg_status_det != 'DF'
           AND lte.id_analysis_req = ar.id_analysis_req)
      
   AND lt.id_analysis_req = ar.id_analysis_req
   AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                              sys_context('ALERT_CONTEXT',
                                                                                          'i_prof_institution'),
                                                                              sys_context('ALERT_CONTEXT',
                                                                                          'i_prof_software')),
                                                                 lt.id_analysis)
          FROM dual) = 'Y';
