CREATE OR REPLACE view v_pat_criteria_active_admin AS
SELECT tbl.query,
       tbl.flg_type,
       tbl.acuity,
       tbl.color_text,
       tbl.rank_acuity,
       tbl.id_episode,
       tbl.id_episode_obs,
       tbl.id_patient,
       tbl.gender,
       pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                               alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                  sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                  sys_context('ALERT_CONTEXT', 'i_prof_software')),
                               tbl.id_patient,
                               tbl.id_episode) name_pat,
       pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                       tbl.id_patient,
                                       tbl.id_episode,
                                       NULL) name_pat_sort,
       pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                       alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                          sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                       tbl.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                          alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                             sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                             sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                          tbl.id_patient) pat_nd_icon,
       tbl.num_clin_record,
       tbl.dt_begin_tstz,
       d.flg_status flg_status_d,
       tbl.dt_birth,
       tbl.dt_deceased,
       tbl.age,
       tbl.flg_type_epis_obs,
       tbl.dt_begin_tstz_obs,
       d.dt_med_tstz,
       d.dt_pend_tstz,
       tbl.flg_status_epis,
       dd.follow_up_date_tstz,
       d.id_disch_reas_dest,
       decode(tbl.query,
              1,
              decode(tbl.flg_type_epis_obs,
                     sys_context('ALERT_CONTEXT', 'g_episode_flg_type_temp'),
                     nvl(least(nvl(tbl.epis_dt_first_obs, sys_context('ALERT_CONTEXT', 'g_sysdate_tstz')),
                               nvl(tbl.epis_dt_first_nurse_obs, sys_context('ALERT_CONTEXT', 'g_sysdate_tstz')),
                               nvl(tbl.epis_dt_first_inst_obs, sys_context('ALERT_CONTEXT', 'g_sysdate_tstz'))),
                         sys_context('ALERT_CONTEXT', 'g_sysdate_tstz')),
                     decode(tbl.flg_status_epis,
                            sys_context('ALERT_CONTEXT', 'g_epis_pending'),
                            d.dt_med_tstz,
                            tbl.dt_begin_tstz)),
              2,
              decode(tbl.flg_status_epis,
                     sys_context('ALERT_CONTEXT', 'g_epis_pending'),
                     d.dt_med_tstz,
                     decode(nvl(tbl.epis_dt_first_obs, tbl.epis_dt_first_nurse_obs), NULL, tbl.dt_begin_tstz))) dt_rank,
       tbl.dt_first_obs_tstz,
       tbl.id_institution,
       tbl.id_software,
       tbl.barcode,
       tbl.name_prof,
       tbl.id_triage_color,
       tbl.id_episode_prev,
       tbl.flg_status_prev
  FROM (SELECT 1 query,
               epis.flg_type,
               epis.triage_acuity acuity,
               epis.triage_color_text color_text,
               to_number(epis.triage_rank_acuity) rank_acuity,
               epis.id_episode,
               epis.id_episode_obs,
               epis.id_patient,
               epis.gender,
               epis.num_clin_record,
               epis.dt_begin_tstz,
               epis.dt_birth,
               epis.dt_deceased,
               epis.age,
               epis.flg_type_epis_obs,
               epis.dt_begin_tstz_obs,
               epis.flg_status flg_status_epis,
               dt_first_inst_obs_tstz dt_first_obs_tstz,
               id_institution,
               id_software,
               barcode,
               name_prof,
               epis.id_triage_color,
               NULL id_episode_prev,
               NULL flg_status_prev,
               epis.dt_first_inst_obs_tstz epis_dt_first_inst_obs,
               epis.dt_first_obs_tstz epis_dt_first_obs,
               epis.dt_first_nurse_obs_tstz epis_dt_first_nurse_obs
          FROM (SELECT v.dt_first_obs_tstz,
                       v.dt_first_nurse_obs_tstz,
                       v.dt_first_inst_obs_tstz,
                       v.id_episode,
                       epis_obs.id_episode       id_episode_obs,
                       v.id_patient,
                       cr.num_clin_record,
                       pat.gender,
                       v.flg_type,
                       v.flg_status_e            flg_status,
                       epis_obs.flg_type         flg_type_epis_obs,
                       pat.dt_birth,
                       pat.dt_deceased,
                       pat.age,
                       v.dt_begin_tstz_e         dt_begin_tstz,
                       epis_obs.dt_begin_tstz    dt_begin_tstz_obs,
                       v.triage_acuity,
                       v.triage_color_text,
                       v.triage_rank_acuity,
                       v.id_institution,
                       v.id_software,
                       v.barcode_e               barcode,
                       p.name                    name_prof,
                       v.id_triage_color
                  FROM v_episode_act_pend v, patient pat, episode epis_obs, clin_record cr, professional p
                 WHERE v.id_episode = epis_obs.id_prev_episode(+)
                   AND epis_obs.id_epis_type(+) = sys_context('ALERT_CONTEXT', 'g_epis_type_inp') -- José Brito 22/07/10 ALERT-113768
                   AND epis_obs.flg_status(+) <> sys_context('ALERT_CONTEXT', 'g_cancelled') -- José Brito 09/02/09 ALERT-9546
                   and epis_obs.flg_type(+) = sys_context('ALERT_CONTEXT', 'g_episode_flg_type_temp')
                   AND v.id_patient = pat.id_patient
                   AND v.id_institution = cr.id_institution(+)
                   AND v.id_patient = cr.id_patient(+)
                   AND cr.flg_status(+) = 'A'
                   AND p.id_professional(+) = v.id_professional
                   AND v.id_software = sys_context('ALERT_CONTEXT', 'i_prof_software')
                   AND (v.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution') OR EXISTS
                        (SELECT 0
                           FROM transfer_institution ti
                          WHERE ti.id_institution_dest = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                            AND ti.id_episode = v.id_episode
                            AND ti.flg_status = sys_context('ALERT_CONTEXT', 'g_transfer_inst_transp')))
                   AND v.flg_ehr = 'N'
                   AND v.flg_status_e IN
                       (sys_context('ALERT_CONTEXT', 'g_epis_active'), sys_context('ALERT_CONTEXT', 'g_epis_pending'))
                   AND (epis_obs.id_episode IS NULL OR NOT EXISTS
                        (SELECT 0
                           FROM discharge d_obs
                          WHERE d_obs.id_episode = epis_obs.id_episode
                            AND d_obs.flg_status = sys_context('ALERT_CONTEXT', 'g_discharge_flg_status_active')))) epis
        UNION ALL
        SELECT 2 query,
               epis.flg_type,
               sys_context('ALERT_CONTEXT', 'g_no_triage') acuity,
               sys_context('ALERT_CONTEXT', 'g_no_triage_color_text') color_text,
               to_number(sys_context('ALERT_CONTEXT', 'g_no_color_rank')) rank_acuity,
               epis.id_episode,
               NULL id_episode_obs,
               epis.id_patient,
               epis.gender,
               epis.num_clin_record,
               epis.dt_begin_tstz,
               epis.dt_birth,
               epis.dt_deceased,
               epis.age,
               NULL flg_type_epis_obs,
               NULL dt_begin_tstz_obs,
               epis.flg_status flg_status_epis,
               nvl(epis.dt_first_obs_tstz, epis.dt_first_nurse_obs_tstz) dt_first_obs_tstz,
               id_institution,
               id_software,
               barcode,
               name_prof,
               NULL id_triage_color,
               id_episode_prev,
               flg_status_prev,
               epis.dt_first_inst_obs_tstz epis_dt_first_inst_obs,
               epis.dt_first_obs_tstz epis_dt_first_obs,
               epis.dt_first_nurse_obs_tstz epis_dt_first_nurse_obs
          FROM (SELECT v.dt_first_obs_tstz,
                       v.dt_first_nurse_obs_tstz,
                       v.dt_first_inst_obs_tstz,
                       v.id_episode,
                       v.id_patient,
                       cr.num_clin_record,
                       pat.gender,
                       v.flg_type,
                       v.flg_status_e            flg_status,
                       pat.dt_birth,
                       pat.dt_deceased,
                       pat.age,
                       v.dt_begin_tstz_e         dt_begin_tstz,
                       v.id_institution,
                       v.id_software,
                       v.barcode_e               barcode,
                       p.name                    name_prof,
                       epis_urg.id_episode       id_episode_prev,
                       epis_urg.flg_status       flg_status_prev
                  FROM v_episode_act_pend v, episode epis_urg, patient pat, clin_record cr, professional p
                 WHERE v.flg_status_e IN ('A', 'P')
                   AND v.id_patient = pat.id_patient
                   AND v.id_institution = cr.id_institution(+)
                   AND v.id_patient = cr.id_patient(+)
                   AND cr.flg_status(+) = 'A'
                   AND p.id_professional(+) = v.id_professional
                   AND epis_urg.id_episode(+) = v.id_prev_episode
                   AND epis_urg.flg_status(+) <> sys_context('ALERT_CONTEXT', 'g_cancelled')
                   AND (v.id_dep_clin_serv IN (SELECT dcs.id_dep_clin_serv
                                                 FROM dep_clin_serv dcs, department dpt
                                                WHERE dpt.id_department = dcs.id_department
                                                  AND dpt.id_institution = v.id_institution
                                                  AND instr(dpt.flg_type, 'I') > 0
                                                  AND instr(dpt.flg_type, 'O') > 0) OR
                       v.flg_type = sys_context('ALERT_CONTEXT', 'g_episode_flg_type_temp'))
                   AND (v.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution') OR EXISTS
                        (SELECT 0
                           FROM transfer_institution ti
                          WHERE ti.id_institution_dest = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                            AND ti.id_episode = v.id_episode
                            AND ti.flg_status = sys_context('ALERT_CONTEXT', 'g_transfer_inst_transp')))
                   AND v.flg_ehr = 'N'
                   AND v.flg_status_e IN
                       (sys_context('ALERT_CONTEXT', 'g_epis_active'), sys_context('ALERT_CONTEXT', 'g_epis_pending'))
                   AND v.id_epis_type = sys_context('ALERT_CONTEXT', 'g_epis_type_inp')) epis) tbl
  LEFT JOIN discharge d ON d.id_episode = tbl.id_episode
                       AND d.flg_status IN
                           (sys_context('ALERT_CONTEXT', 'g_discharge_flg_status_active'),
                            sys_context('ALERT_CONTEXT', 'g_discharge_flg_status_pend'))
  LEFT JOIN discharge_detail dd ON dd.id_discharge = d.id_discharge
 WHERE tbl.query = 1
    OR (tbl.query = 2 AND (d.id_discharge IS NOT NULL OR tbl.id_episode_prev IS NULL OR
       tbl.flg_status_prev = sys_context('ALERT_CONTEXT', 'g_epis_inactive')));
/
