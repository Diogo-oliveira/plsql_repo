CREATE OR REPLACE VIEW V_EPIS_INACT_LTECH AS
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
 NULL id_schedule,
 t.id_task,
 NULL priority,
 NULL status_string,
 t.flg_result,
 NULL flg_contact,
 NULL flg_state,
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
 t.flg_time_harvest,
 t.flg_status_ard,
 t.dt_req_tstz,
 t.dt_pend_req_tstz,
 t.dt_target_tstz,
 t.dt_harvest_tstz,
 t.dt_begin_tstz         dt_begin_tstz_m,
 t.dt_end_tstz,
 t.dt_mov_begin_tstz,
 t.dt_lab_reception_tstz,
 t.flg_referral,
 t.flg_status_h,
 t.flg_status_result
  FROM clin_record cr,
       episode epis,
       epis_info ei,
       patient pat,
       (SELECT ar.id_episode,
               ard.id_analysis_req_det id_req,
               ah.id_sample_recipient id_task,
               ard.flg_time_harvest,
               ard.flg_status flg_status_ard,
               ar.dt_req_tstz,
               ard.dt_pend_req_tstz,
               ard.dt_target_tstz,
               h.dt_harvest_tstz,
               m.dt_begin_tstz,
               m.dt_end_tstz,
               h.dt_mov_begin_tstz,
               h.dt_lab_reception_tstz,
               ard.flg_referral,
               h.flg_status flg_status_h,
               CASE
                    WHEN ard.flg_status = 'F' THEN
                     CASE
                         WHEN ard.flg_urgency != 'N'
                              OR ares.flg_urgent = 'Y' THEN
                          rs.value || 'U'
                         ELSE
                          rs.value
                     END
                    ELSE
                     rs.value
                END flg_status_result,
               CAST(NULL AS VARCHAR2(1)) flg_result
          FROM analysis_req ar
         INNER JOIN analysis_req_det ard
            ON ard.id_analysis_req = ar.id_analysis_req
          LEFT OUTER JOIN analysis_harvest ah
            ON ah.id_analysis_req_det = ard.id_analysis_req_det
          LEFT OUTER JOIN harvest h
            ON h.id_harvest = ah.id_harvest
          LEFT OUTER JOIN movement m
            ON m.id_movement = ard.id_movement
          LEFT OUTER JOIN (SELECT ar.id_analysis_req_det,
                                 ar.id_result_status,
                                 CASE
                                      WHEN pk_utils.is_number(dbms_lob.substr(ar.desc_analysis_result, 3800)) = 'Y'
                                           AND ar.analysis_result_value_2 IS NULL THEN
                                       CASE
                                           WHEN ar.analysis_result_value_1 < ar.ref_val_min THEN
                                            'Y'
                                           WHEN ar.analysis_result_value_1 > ar.ref_val_max THEN
                                            'Y'
                                           ELSE
                                            'N'
                                       END
                                      ELSE
                                       CASE
                                           WHEN ar.id_abnormality IS NOT NULL
                                                AND ar.id_abnormality != 7 THEN
                                            'Y'
                                           ELSE
                                            'N'
                                       END
                                  END flg_urgent
                            FROM (SELECT ar.id_analysis_req_det,
                                         ar.id_result_status,
                                         arp.desc_analysis_result,
                                         arp.analysis_result_value_1,
                                         arp.analysis_result_value_2,
                                         arp.ref_val_min,
                                         arp.ref_val_max,
                                         arp.id_abnormality,
                                         row_number() over(PARTITION BY id_harvest, id_analysis_req_par ORDER BY dt_ins_result_tstz DESC) rn
                                    FROM analysis_result ar, analysis_result_par arp
                                   WHERE ar.id_episode_orig = nvl(ar.id_episode, ar.id_episode_orig)
                                     AND ar.id_analysis_result = arp.id_analysis_result) ar
                           WHERE ar.rn = 1) ares
            ON ares.id_analysis_req_det = ard.id_analysis_req_det
          LEFT OUTER JOIN result_status rs
            ON rs.id_result_status = ares.id_result_status
         WHERE ard.flg_status != 'C'
           AND (EXISTS (SELECT 1
                          FROM institution i
                         WHERE i.id_parent =
                               (SELECT i.id_parent
                                  FROM institution i
                                 WHERE i.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))
                           AND i.id_institution = ar.id_institution) OR
                ar.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution'))) t,
       (SELECT ltea.id_episode,
               ltea.id_analysis_req_det   id_req,
               ltea.flg_status_det,
               ah.id_harvest,
               ltea.dt_target             dt_begin,
               ltea.id_task_dependency,
               ltea.flg_req_origin_module
          FROM lab_tests_ea ltea, analysis_harvest ah
         WHERE ltea.flg_status_det NOT IN ('DF', 'C')
           AND ah.id_analysis_req_det(+) = ltea.id_analysis_req_det) t1
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
 ORDER BY order_name;
 /
