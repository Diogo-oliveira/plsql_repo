CREATE OR REPLACE view v_epis_cancelled AS
    SELECT t."QUERY",
           t."FLG_TYPE",
           t."ACUITY",
           t."COLOR_TEXT",
           t."RANK_ACUITY",
           t."ID_EPISODE",
           t."ID_PATIENT",
           cr.num_clin_record,
           t."DT_BEGIN_TSTZ",
           t."FLG_STATUS_D",
           t."FLG_TYPE_EPIS_OBS",
           t."DT_BEGIN_TSTZ_OBS",
           t."DT_MED_TSTZ",
           t."DT_PEND_TSTZ",
           t."FLG_STATUS_EPIS",
           t."FOLLOW_UP_DATE_TSTZ",
           t."ID_DISCH_REAS_DEST",
           t."DT_RANK",
           t."DT_FIRST_OBS_TSTZ",
           t."ID_SOFTWARE",
           t."ID_INSTITUTION",
           t."BARCODE",
           t."ID_PROFESSIONAL",
           pk_patient.get_pat_name(sys_context('ALERT_CONTEXT', 'i_lang'),
                                   alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                      sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                      sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                   t.id_patient,
                                   t.id_episode) name_pat,
           pk_patient.get_pat_name_to_sort(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                              sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                              sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                           t.id_patient,
                                           t.id_episode,
                                           NULL) name_pat_sort,
           pk_adt.get_pat_non_disc_options(sys_context('ALERT_CONTEXT', 'i_lang'),
                                           alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                              sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                              sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                           t.id_patient) pat_ndo,
           pk_adt.get_pat_non_disclosure_icon(sys_context('ALERT_CONTEXT', 'i_lang'),
                                              alert.profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                 sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                 sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                              t.id_patient) pat_nd_icon,
           pat.gender,
           pat.age,
           pat.dt_birth,
           pat.dt_deceased,
           p.name name_prof
      FROM (SELECT 1 query,
                   epis.flg_type,
                   epis.triage_acuity acuity,
                   epis.triage_color_text color_text,
                   to_number(epis.triage_rank_acuity) rank_acuity,
                   epis.id_episode,
                   epis.id_patient,
                   epis.dt_begin_tstz,
                   NULL flg_status_d,
                   epis.flg_type_epis_obs,
                   epis.dt_begin_tstz_obs,
                   NULL dt_med_tstz,
                   NULL dt_pend_tstz,
                   epis.flg_status flg_status_epis,
                   NULL follow_up_date_tstz,
                   NULL id_disch_reas_dest,
                   NULL dt_rank,
                   nvl(epis.dt_first_obs_tstz, dt_first_nurse_obs_tstz) dt_first_obs_tstz,
                   epis.id_software,
                   epis.id_institution,
                   epis.barcode,
                   epis.id_professional
              FROM (SELECT epis.id_episode,
                           epis.id_patient,
                           epis.flg_type,
                           epis.flg_status,
                           epis_obs.flg_type          flg_type_epis_obs,
                           epis.dt_begin_tstz,
                           epis_obs.dt_begin_tstz     dt_begin_tstz_obs,
                           ei.id_software,
                           epis.id_institution,
                           epis.barcode,
                           ei.id_professional,
                           ei.dt_first_obs_tstz,
                           ei.dt_first_nurse_obs_tstz,
                           ei.triage_acuity,
                           ei.triage_color_text,
                           ei.triage_rank_acuity
                      FROM episode epis, epis_info ei, episode epis_obs
                     WHERE ei.id_episode = epis.id_episode
                       AND epis.id_episode = epis_obs.id_prev_episode(+)
                       AND ei.id_software = sys_context('ALERT_CONTEXT', 'i_prof_software')
                       AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                       AND epis.flg_status = sys_context('ALERT_CONTEXT', 'g_cancelled')) epis
            UNION ALL
            SELECT 2 query,
                   epis.flg_type,
                   sys_context('ALERT_CONTEXT', 'g_no_triage') acuity,
                   sys_context('ALERT_CONTEXT', 'g_no_triage_color_text') color_text,
                   to_number(sys_context('ALERT_CONTEXT', 'g_no_color_rank')) rank_acuity,
                   epis.id_episode,
                   epis.id_patient,
                   epis.dt_begin_tstz,
                   NULL flg_status_d,
                   NULL flg_type_epis_obs,
                   NULL dt_begin_tstz_obs,
                   NULL dt_med_tstz,
                   NULL dt_pend_tstz,
                   epis.flg_status flg_status_epis,
                   NULL follow_up_date_tstz,
                   NULL id_disch_reas_dest,
                   NULL dt_rank,
                   nvl(epis.dt_first_obs_tstz, epis.dt_first_nurse_obs_tstz) dt_first_obs_tstz,
                   epis.id_software,
                   epis.id_institution,
                   epis.barcode,
                   epis.id_professional
              FROM (SELECT epis.id_episode,
                           epis.id_patient,
                           epis.flg_type,
                           epis.flg_status,
                           epis.dt_begin_tstz,
                           ei.id_software,
                           epis.id_institution,
                           epis.barcode,
                           ei.id_professional,
                           ei.dt_first_obs_tstz,
                           ei.dt_first_nurse_obs_tstz
                      FROM episode epis, epis_info ei
                     WHERE ei.id_episode = epis.id_episode
                       AND ei.id_dep_clin_serv IN (SELECT dcs.id_dep_clin_serv
                                                     FROM dep_clin_serv dcs, department dpt
                                                    WHERE dpt.id_department = dcs.id_department
                                                      AND dpt.id_institution = epis.id_institution
                                                      AND instr(dpt.flg_type, 'I') > 0
                                                      AND instr(dpt.flg_type, 'O') > 0)
                       AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
                       AND epis.flg_status = sys_context('ALERT_CONTEXT', 'g_cancelled')
                       AND epis.id_epis_type != sys_context('ALERT_CONTEXT', 'g_epis_type_urg')) epis) t,
           patient pat,
           professional p,
           clin_record cr
     WHERE pat.id_patient = t.id_patient
       AND p.id_professional(+) = t.id_professional
       AND t.id_institution = cr.id_institution(+)
       AND t.id_patient = cr.id_patient(+)
       AND cr.flg_status(+) = 'A';
/
