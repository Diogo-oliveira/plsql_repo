CREATE OR REPLACE VIEW V_EPISODE_URG_LAST_8 AS 
SELECT id_episode,
       institution,
       dt_episode_begin,
       admission_speciality,
       professional_spec_last,
       last_room,
       last_department,
       ext_episode episode_ext,
       patient_number patient_ext,
       process_number,
       num_mecan num_mecan_first_med,
       num_order num_order_first_med,
       et_min_id_triage_color id_triage_color,
       triage_color color_triage_desc,
       dt_triage_begin,
       dt_triage_end,
       triage_type,
       num_mecan_triage,
       et_min_category triage_prof_category,
       order_number_triage,
       dt_begin_retriage,
       dt_end_retriage,
       order_number_retriage,
       num_mecan_retriage,
       et_max_category retriage_prof_category,
       triage_color_retriage,
       id_triage_color_retriage id_retriage_color,
       dt_first_responsability,
       dt_last_responsability,
       decode(qtd_valencias_atend_urg, 0, 1, qtd_valencias_atend_urg) qtd_valencias_atend_urg,
       dt_first_obs dt_first_med_observation,
       dt_first_nurse_obs dt_first_nurse_observation,
       num_mecan_last_nurse,
       dt_admin_disch,
       dt_med_disch,
       day_med_disch,
       month_med_disch,
       day_admin_disch,
       month_admin_disch,
       med_order_number_discharge,
       med_num_mecan_discharge,
       dt_birth patient_dt_birth,
       pat_birth,
       gender,
       gender_desc,
       national_health_number,
       id_origin,
       desc_origin,
       id_external_cause,
       desc_external_cause,
       id_disch_reason,
       id_dis_reas_dest,
       discharge_reason_desc,
       discharge_dest_desc,
       diagnosis_desc,
       diagnosis_code,
       id_institution,
       dt_begin_tstz,
       initial_institution,
       contact_name,
       county
  FROM (SELECT (SELECT pk_date_utils.date_send_tsz(language_id, dt_episode_begin, profissional(0, id_institution, 0))
                  FROM dual) dt_episode_begin,
               dt_episode_begin dt_begin_tstz,
               id_episode,
               id_institution,
               (SELECT pk_date_utils.date_send_tsz(language_id, dt_alta_med, profissional(0, id_institution, 0))
                  FROM dual) dt_med_disch,
               (SELECT pk_date_utils.date_yearmonthday_tsz(language_id, dt_alta_med, id_institution, 0)
                  FROM dual) day_med_disch,
               (SELECT pk_date_utils.date_yearmonth_tsz(language_id, dt_alta_med, id_institution, 0)
                  FROM dual) month_med_disch,
               (SELECT pk_date_utils.date_send_tsz(language_id, dt_alta_admin, profissional(0, id_institution, 0))
                  FROM dual) dt_admin_disch,
               (SELECT pk_date_utils.date_yearmonthday_tsz(language_id, dt_alta_admin, id_institution, 0)
                  FROM dual) day_admin_disch,
               (SELECT pk_date_utils.date_yearmonth_tsz(language_id, dt_alta_admin, id_institution, 0)
                  FROM dual) month_admin_disch,
               ext_episode,
               num_paciente patient_number,
               num_processo process_number,
               nick_name,
               num_mecan,
               num_order,
               (SELECT pk_utils.get_institution_name(language_id, id_institution)
                  FROM dual) AS institution, -- EMR-805
               (SELECT pk_translation.get_translation(language_id,
                                                      'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || id_clinical_service)
                  FROM dual) AS admission_speciality,
               (SELECT pk_translation.get_translation(language_id, 'ROOM.CODE_ROOM.' || id_actual_room)
                  FROM dual) AS last_room,
               (SELECT pk_translation.get_translation(language_id, 'DEPARTMENT.CODE_DEPARTMENT.' || id_department)
                  FROM dual) AS last_department,
               (SELECT pk_translation.get_translation(language_id,
                                                      'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || et_min_id_triage_color)
                  FROM dual) AS triage_color,
               (SELECT pk_date_utils.date_send_tsz(language_id,
                                                   et_min_dt_triage_begin,
                                                   profissional(0, id_institution, 0))
                  FROM dual) dt_triage_begin,
               (SELECT pk_date_utils.date_send_tsz(language_id, et_min_dt_triage_end, profissional(0, id_institution, 0))
                  FROM dual) dt_triage_end,
               triage_type,
               et_min_id_triage_color,
               et_min_category,
               (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id,
                                                           profissional(et_min_id_professional, id_institution, 0))
                  FROM dual) num_mecan_triage,
               decode(et_min_category,
                      'D',
                      (SELECT pk_prof_utils.get_prof_num_order(language_id,
                                                               profissional(et_min_id_professional, id_institution, 0))
                         FROM dual)) order_number_triage,
               decode(id_epis_triage_max,
                      id_epis_triage_min,
                      NULL,
                      (SELECT pk_date_utils.date_send_tsz(language_id,
                                                          et_max_dt_triage_begin,
                                                          profissional(0, id_institution, 0))
                         FROM dual)) dt_begin_retriage,
               decode(id_epis_triage_max,
                      id_epis_triage_min,
                      NULL,
                      (SELECT pk_date_utils.date_send_tsz(language_id,
                                                          et_max_dt_triage_end,
                                                          profissional(0, id_institution, 0))
                         FROM dual)) dt_end_retriage,
               decode(id_epis_triage_max,
                      id_epis_triage_min,
                      NULL,
                      (SELECT pk_translation.get_translation(language_id,
                                                             'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || et_max_id_triage_color)
                         FROM dual)) AS triage_color_retriage,
               decode(id_epis_triage_max, id_epis_triage_min, NULL, et_max_id_triage_color) id_triage_color_retriage,
               decode(id_epis_triage_max, id_epis_triage_min, NULL, et_max_category) et_max_category,
               decode(et_max_category,
                      'D',
                      (SELECT pk_prof_utils.get_prof_num_order(language_id,
                                                               profissional(et_max_id_professional, id_institution, 0))
                         FROM dual)) order_number_retriage,
               decode(id_epis_triage_max,
                      id_epis_triage_min,
                      NULL,
                      (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id,
                                                                  profissional(et_max_id_professional, id_institution, 0))
                         FROM dual)) num_mecan_retriage,
               (SELECT COUNT(DISTINCT edcs.id_dep_clin_serv)
                  FROM alert.epis_prof_resp a
                  JOIN epis_prof_dcs edcs
                    ON edcs.id_episode = a.id_episode
                   AND edcs.id_professional = a.id_prof_comp
                  JOIN dep_clin_serv dcs
                    ON edcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                 WHERE a.flg_status = 'F'
                   AND a.flg_type = 'D'
                   AND edcs.dt_reg <= (a.dt_comp_tstz + numtodsinterval(4, 'SECOND'))
                   AND a.id_episode = t.id_episode) qtd_valencias_atend_urg,
               (SELECT pk_date_utils.date_send_tsz(language_id, dt_first_obs_tstz, profissional(0, id_institution, 0))
                  FROM dual) dt_first_obs,
               (SELECT pk_date_utils.date_send_tsz(language_id,
                                                   dt_first_nurse_obs_tstz,
                                                   profissional(0, id_institution, 0))
                  FROM dual) dt_first_nurse_obs,
               (SELECT pk_date_utils.date_send_tsz(language_id,
                                                   dt_first_responsability,
                                                   profissional(0, id_institution, 0))
                  FROM dual) dt_first_responsability,
               (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id,
                                                           profissional(id_last_nurse_resp, id_institution, 0))
                  FROM dual) num_mecan_last_nurse,
               decode(id_actual_prof_resp,
                      id_first_prof_resp,
                      NULL,
                      (SELECT pk_date_utils.date_send_tsz(language_id,
                                                          dt_last_responsability,
                                                          profissional(0, id_institution, 0))
                         FROM dual)) dt_last_responsability,
               (SELECT pk_prof_utils.get_prof_num_order(language_id,
                                                        profissional(id_prof_med_discharge, id_institution, 0))
                  FROM dual) med_order_number_discharge,
               (SELECT pk_prof_utils.get_prof_inst_mec_num(language_id,
                                                           profissional(id_prof_med_discharge, id_institution, 0))
                  FROM dual) med_num_mecan_discharge,
               coalesce((SELECT pk_translation.get_translation(language_id,
                                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                              id_clinical_service_dest)
                          FROM dual),
                        (SELECT alert.pk_prof_utils.get_spec_signature(language_id,
                                                                       profissional(id_prof_to_actual, id_institution, 8),
                                                                       id_prof_to_actual,
                                                                       dt_last_responsability,
                                                                       id_episode)
                           FROM dual)) professional_spec_last,
               (SELECT pk_date_utils.date_yearmonthday_tsz(language_id, dt_birth, id_institution, 0)
                  FROM dual) dt_birth,
               gender,
               dt_birth pat_birth,
               (SELECT pk_sysdomain.get_domain('PATIENT.GENDER', gender, language_id)
                  FROM dual) gender_desc,
               national_health_number,
               id_origin,
               (SELECT pk_translation.get_translation(language_id, 'ORIGIN.CODE_ORIGIN.' || id_origin)
                  FROM dual) desc_origin,
               id_external_cause,
               (SELECT pk_translation.get_translation(language_id,
                                                      'EXTERNAL_CAUSE.CODE_EXTERNAL_CAUSE.' || id_external_cause)
                  FROM dual) desc_external_cause,
               (SELECT pk_translation.get_translation(language_id, dr.code_discharge_reason)
                  FROM discharge_reason dr
                 WHERE dr.id_discharge_reason = id_disch_reason) discharge_reason_desc,
               id_dis_reas_dest,
               id_disch_reason,
               (SELECT vr.desc_discharge_dest
                  FROM v_disch_reas_dest vr
                 WHERE vr.id_disch_reas_dest = id_dis_reas_dest
                   AND vr.id_discharge_reason = id_disch_reason
                   AND vr.id_disch_dest = id_dest
                   AND vr.id_language = language_id) discharge_dest_desc,
               nvl(desc_epis_diagnosis,
                   decode(id_alert_diagnosis,
                          NULL,
                          pk_translation.get_translation(language_id, code_diagnosis),
                          pk_translation.get_translation(language_id, code_alert_diagnosis))) diagnosis_desc,
               code_icd diagnosis_code,
               language_id,
               pk_adt.get_patient_address_colony(id_person) AS county, -- EMR-805
               pk_patient.get_patient_name(language_id, id_patient) AS contact_name, -- emr-806
               initial_institution -- EMR-806
          FROM (WITH epis AS (SELECT /*+ materialize */
                               *
                                FROM alert.episode
                               WHERE flg_status != 'C'
                                 AND id_epis_type = 2
                                 AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY'))
                   SELECT /* + index (e epi_supp1_idx) index (pi1 prins_supp1_idx)*/
                    e.dt_begin_tstz dt_episode_begin,
                    e.id_episode,
                    e.id_institution,
                    e.id_clinical_service,
                    ei.dt_med_tstz dt_alta_med,
                    ei.dt_admin_tstz dt_alta_admin,
                    ei.dt_first_obs_tstz AS dt_first_obs_tstz,
                    ei.dt_first_nurse_obs_tstz,
                    epr.dt_comp_tstz AS dt_first_responsability,
                    epr_actual.dt_comp_tstz AS dt_last_responsability,
                    epr.id_epis_prof_resp AS id_first_prof_resp,
                    epr_actual.id_epis_prof_resp AS id_actual_prof_resp,
                    et_min_id_triage_color,
                    ees.value ext_episode,
                    pes.value num_paciente,
                    crec.num_clin_record AS num_processo,
                    p1.nick_name nick_name,
                    (SELECT pk_prof_utils.get_prof_inst_mec_num(1, profissional(epr.id_prof_to, e.id_institution, 0))
                       FROM dual) num_mecan, -- da primeira responsabilidade
                    (SELECT pk_prof_utils.get_category(1, profissional(et_min_id_professional, e.id_institution, 0))
                       FROM dual) et_min_category,
                    p1.num_order,
                    et_min_dt_triage_begin,
                    et_min_dt_triage_end,
                    et_min_rank,
                    et_min_id_professional,
                    et_max_id_triage_color,
                    et_max_dt_triage_begin,
                    et_max_dt_triage_end,
                    et_max_rank,
                    id_epis_triage_max,
                    et_max_id_professional,
                    (SELECT pk_prof_utils.get_category(1, profissional(et_max_id_professional, e.id_institution, 0))
                       FROM dual) et_max_category,
                    acronym triage_type,
                    ei.id_room id_actual_room,
                    id_epis_triage_min,
                    epr_actual.id_clinical_service_dest,
                    epr_actual.id_prof_to id_prof_to_actual,
                    epr_actual.dt_comp_tstz,
                    d.id_department,
                    p.dt_birth,
                    p.gender,
                    (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                       FROM dual) language_id,
                    epr_last_nur.id_prof_comp id_last_nurse_resp,
                    disch.id_prof_med id_prof_med_discharge,
                    p.national_health_number,
                    v.id_origin,
                    v.id_external_cause,
                    id_discharge_reason id_disch_reason,
                    disch.id_disch_reas_dest id_dis_reas_dest,
                    diag.code_alert_diagnosis,
                    diag.code_diagnosis,
                    diag.desc_epis_diagnosis,
                    diag.id_alert_diagnosis,
                    diag.code_icd,
                    p.id_patient, -- EMR-806
                    p.id_person, -- EMR-805
                    in_inst.initial_institution, -- EMR-806
                    disch.id_dest
                     FROM epis e
                     JOIN alert.epis_info ei
                       ON ei.id_episode = e.id_episode
                     JOIN patient p
                       ON ei.id_patient = p.id_patient
                   --primeira instituicao -- EMR-806
                     LEFT OUTER JOIN (SELECT e.id_episode,
                                             pk_utils.get_institution_name(1, i.id_institution) initial_institution
                                        FROM epis_info ei, episode e, dep_clin_serv dc, department d, institution i
                                       WHERE e.id_episode = ei.id_episode
                                         AND dc.id_dep_clin_serv = ei.id_first_dep_clin_serv
                                         AND d.id_department = dc.id_department
                                         AND d.id_institution = i.id_institution) in_inst
                       ON (in_inst.id_episode = e.id_episode)
                   --primeira triagem
                     LEFT OUTER JOIN (SELECT et_min.id_triage_color AS et_min_id_triage_color,
                                             et_min.dt_begin_tstz AS et_min_dt_triage_begin,
                                             et_min.dt_end_tstz AS et_min_dt_triage_end,
                                             et_min.id_episode,
                                             et_min.id_professional et_min_id_professional,
                                             et_min.id_epis_triage id_epis_triage_min,
                                             tt.acronym,
                                             rank() over(PARTITION BY et_min.id_episode ORDER BY et_min.dt_end_tstz ASC) AS et_min_rank
                                        FROM alert.epis_triage et_min
                                        LEFT JOIN triage t
                                          ON t.id_triage = et_min.id_triage
                                        LEFT JOIN triage_type tt
                                          ON tt.id_triage_type = t.id_triage_type) et_min
                       ON (et_min.id_episode = e.id_episode)
                   -- retriagem
                     LEFT OUTER JOIN (SELECT et_max.id_triage_color AS et_max_id_triage_color,
                                             et_max.dt_begin_tstz AS et_max_dt_triage_begin,
                                             et_max.dt_end_tstz AS et_max_dt_triage_end,
                                             et_max.id_episode,
                                             et_max.id_professional et_max_id_professional,
                                             et_max.id_epis_triage id_epis_triage_max,
                                             rank() over(PARTITION BY et_max.id_episode ORDER BY et_max.dt_end_tstz DESC) AS et_max_rank
                                        FROM alert.epis_triage et_max) et_max
                       ON (et_max.id_episode = e.id_episode)
                   -- primeira responsabilidade médica
                     LEFT OUTER JOIN (SELECT a.*,
                                             rank() over(PARTITION BY a.id_episode ORDER BY a.dt_request_tstz ASC) AS rank1
                                        FROM alert.epis_prof_resp a
                                       WHERE a.flg_status = 'F'
                                         AND a.flg_type = 'D') epr
                       ON (epr.id_episode = e.id_episode)
                   -- ultima responsabilidade
                     LEFT OUTER JOIN (SELECT a.*,
                                             rank() over(PARTITION BY a.id_episode ORDER BY a.dt_request_tstz DESC) AS rank1
                                        FROM alert.epis_prof_resp a
                                       WHERE a.flg_status = 'F'
                                         AND a.flg_type = 'D') epr_actual
                       ON (epr_actual.id_episode = e.id_episode)
                   -- ultima responsabilidade de enfermagem 
                     LEFT OUTER JOIN (SELECT a.*,
                                             rank() over(PARTITION BY a.id_episode ORDER BY a.dt_request_tstz DESC) AS rank1
                                        FROM alert.epis_prof_resp a
                                       WHERE a.flg_status = 'F'
                                         AND a.flg_type = 'N') epr_last_nur
                       ON (epr_last_nur.id_episode = e.id_episode)
                     LEFT OUTER JOIN (SELECT d.*,
                                             drd.id_discharge_reason,
                                             coalesce(drd.id_discharge_dest, drd.id_dep_clin_serv, drd.id_department) id_dest,
                                             rank() over(PARTITION BY d.id_episode ORDER BY d.dt_med_tstz DESC, d.dt_admin_tstz DESC) AS rn
                                        FROM alert.discharge d
                                        JOIN disch_reas_dest drd
                                          ON drd.id_disch_reas_dest = d.id_disch_reas_dest
                                       WHERE d.flg_status IN ('A', 'P')) disch
                       ON (disch.id_episode = e.id_episode)
                   -- diagnosticos finais confirmados e o primário
                     LEFT OUTER JOIN (SELECT ed.*,
                                             d.code_diagnosis,
                                             ad.code_alert_diagnosis,
                                             d.code_icd,
                                             rank() over(PARTITION BY ed.id_episode ORDER BY ed.dt_epis_diagnosis_tstz DESC) AS rn
                                        FROM epis_diagnosis ed
                                        JOIN diagnosis d
                                          ON d.id_diagnosis = ed.id_diagnosis
                                        LEFT OUTER JOIN alert_diagnosis ad
                                          ON ad.id_alert_diagnosis = ed.id_alert_diagnosis
                                       WHERE ed.flg_status NOT IN ('C', 'R')
                                         AND ed.flg_type = 'D'
                                         AND ed.flg_final_type = 'P') diag
                       ON (diag.id_episode = e.id_episode)
                     JOIN alert.epis_ext_sys ees
                       ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution AND
                          ees.id_epis_type = 2)
                     JOIN visit v
                       ON e.id_visit = v.id_visit
                     LEFT OUTER JOIN alert.professional p1
                       ON (p1.id_professional = epr.id_prof_to)
                     JOIN alert_adtcod.pat_ext_sys pes
                       ON (pes.id_patient = e.id_patient AND pes.id_institution = e.id_institution)
                     JOIN alert_adtcod.clin_record crec
                       ON (crec.id_patient = e.id_patient AND crec.id_institution = e.id_institution)
                     JOIN room ra
                       ON ra.id_room = ei.id_room
                     JOIN department d
                       ON ra.id_department = d.id_department
                    WHERE (et_min.et_min_rank = 1 OR et_min.et_min_rank IS NULL)
                      AND (et_max.et_max_rank = 1 OR et_max.et_max_rank IS NULL)
                      AND (epr.rank1 = 1 OR epr.rank1 IS NULL)
                      AND (disch.rn = 1 OR disch.rn IS NULL)
                      AND (diag.rn = 1 OR diag.rn IS NULL)
                      AND (epr_actual.rank1 = 1 OR epr_actual.rank1 IS NULL)
                      AND (epr_last_nur.rank1 = 1 OR epr_last_nur.rank1 IS NULL)) t
        );
