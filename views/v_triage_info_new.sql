CREATE OR REPLACE VIEW V_TRIAGE_INFO_NEW as
SELECT id_episode,
       instituicao,
       especialidade_admissao,
       especialidade_profissional,
       sala_primeiro_destino,
       sala_atual,
       servico_atual,
       ext_episode,
       num_paciente,
       num_processo,
       num_mecan,
       num_order,
       triage_color,
       dt_triage_begin,
       dt_triage_end,
       triage_color_retriagem,
       dt_begin_retriagem,
       dt_end_retriagem,
       dt_episode_begin,
       dt_first_responsability,
       dt_last_responsability,
       dt_first_obs,
       dt_first_nurse_obs,
       dt_alta_admin,
       dt_alta_med,
       num_order_last_prof,
       num_mecan_last_prof,
       diagnosis_code,
       diagnosis_desc
  FROM (SELECT dt_episode_begin,
               id_episode,
               dt_alta_med,
               dt_alta_admin,
               ext_episode,
               num_paciente,
               num_processo,
               nick_name,
               num_mecan,
               num_order,
               (SELECT pk_utils.get_institution_name(language_id, id_institution)
                  FROM dual) AS instituicao, -- EMR-805 instituicao,
               id_clinical_service,   
               (SELECT pk_translation.get_translation(1, 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || id_clinical_service)
                  FROM dual) AS especialidade_admissao,
               (SELECT pk_translation.get_translation(1, 'ROOM.CODE_ROOM.' || id_room_to)
                  FROM dual) AS sala_primeiro_destino,
               (SELECT pk_translation.get_translation(1, 'ROOM.CODE_ROOM.' || id_actual_room)
                  FROM dual) AS sala_atual,
               (SELECT pk_translation.get_translation(1, 'DEPARTMENT.CODE_DEPARTMENT.' || id_department)
                  FROM dual) AS servico_atual,
               (SELECT pk_translation.get_translation(1, 'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || et_min_id_triage_color)
                  FROM dual) AS triage_color,
               decode(id_epis_triage_max,
                      id_epis_triage_min,
                      NULL,
                      (SELECT pk_translation.get_translation(1,
                                                             'TRIAGE_COLOR.CODE_TRIAGE_COLOR.' || et_max_id_triage_color)
                         FROM dual)) AS triage_color_retriagem,
               et_min_dt_triage_begin dt_triage_begin,
               CAST(decode(id_epis_triage_max, id_epis_triage_min, NULL, et_max_dt_triage_begin) AS TIMESTAMP WITH LOCAL TIME ZONE) AS dt_begin_retriagem,
               CAST(decode(id_epis_triage_max, id_epis_triage_min, NULL, et_max_dt_triage_end) AS TIMESTAMP WITH LOCAL TIME ZONE) AS dt_end_retriagem,
               et_min_dt_triage_end dt_triage_end,
               dt_first_obs_tstz dt_first_obs,
               dt_first_nurse_obs_tstz dt_first_nurse_obs,
               dt_first_responsability,
               decode(id_actual_prof_resp, id_first_prof_resp, NULL, dt_last_responsability) dt_last_responsability,
               coalesce((SELECT pk_translation.get_translation(1,
                                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                              id_clinical_service_dest)
                          FROM dual),
                        (SELECT alert.pk_prof_utils.get_spec_signature(1,
                                                                       profissional(id_prof_to_actual, id_institution, 8),
                                                                       id_prof_to_actual,
                                                                       dt_last_responsability,
                                                                       id_episode)
                           FROM dual)) especialidade_profissional,
               num_order_last_prof,
               num_mecan_last_prof,
               code_icd diagnosis_code,
               nvl(desc_epis_diagnosis,
                   decode(id_alert_diagnosis,
                          NULL,
                          pk_translation.get_translation(language_id, code_diagnosis),
                          pk_translation.get_translation(language_id, code_alert_diagnosis))) diagnosis_desc               
          FROM (SELECT /* + index (e epi_supp1_idx) index (pi1 prins_supp1_idx)*/
                 e.dt_begin_tstz                     dt_episode_begin,
                 e.id_episode,
                 e.id_institution,
                 e.id_clinical_service,
                 ei.dt_med_tstz                      dt_alta_med,
                 ei.dt_admin_tstz                    dt_alta_admin,
                 ei.dt_first_obs_tstz                AS dt_first_obs_tstz,
                 ei.dt_first_nurse_obs_tstz,
                 epr.dt_comp_tstz                    AS dt_first_responsability,
                 epr_actual.dt_comp_tstz             AS dt_last_responsability,
                 epr.id_epis_prof_resp               AS id_first_prof_resp,
                 epr_actual.id_epis_prof_resp        AS id_actual_prof_resp,
                 et_min_id_triage_color,
                 ees.value                           ext_episode,
                 pes.value                           num_paciente,
                 crec.num_clin_record                AS num_processo,
                 p1.nick_name                        nick_name,
                 pi1.num_mecan                       num_mecan, -- da primeira responsabilidade
                 p1.num_order,
                 p2.num_order                        num_order_last_prof,
                 pi2.num_mecan                       num_mecan_last_prof, -- da primeira responsabilidade
                 et_min_dt_triage_begin,
                 et_min_dt_triage_end,
                 et_min_rank,
                 et_max_id_triage_color,
                 et_max_dt_triage_begin,
                 et_max_dt_triage_end,
                 et_max_rank,
                 mov.id_room_to,
                 ei.id_room                          id_actual_room,
                 id_epis_triage_min,
                 id_epis_triage_max,
                 epr_actual.id_clinical_service_dest,
                 epr_actual.id_prof_to               id_prof_to_actual,
                 epr_actual.dt_comp_tstz,
                 d.id_department,
                 diag.code_diagnosis,
                 diag.desc_epis_diagnosis,
                 diag.code_icd,
                 diag.id_alert_diagnosis,
                 diag.code_alert_diagnosis,
                 (SELECT pk_sysconfig.get_config('LANGUAGE', e.id_institution, 0)
                       FROM dual) language_id
                  FROM (SELECT *
                          FROM alert.episode
                         WHERE flg_status != 'C'
                           AND id_epis_type = 2
                           AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY')
                           AND rownum > 0) e
                  JOIN alert.epis_info ei
                    ON ei.id_episode = e.id_episode
                --diagnosticos finais confirmados e o primário
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
                                    WHERE ed.flg_status NOT IN ('C','R')
                                      AND ed.flg_type = 'D'
                                      AND ed.flg_final_type = 'P') diag
                                ON (diag.id_episode = e.id_episode)
                --primeira triagem
                  LEFT OUTER JOIN (SELECT /*+ use_nl(e1 et_min)*/
                                   et_min.id_triage_color AS et_min_id_triage_color,
                                   et_min.dt_begin_tstz AS et_min_dt_triage_begin,
                                   et_min.dt_end_tstz AS et_min_dt_triage_end,
                                   et_min.id_episode,
                                   et_min.id_professional,
                                   et_min.id_epis_triage id_epis_triage_min,
                                   rank() over(PARTITION BY et_min.id_episode ORDER BY et_min.dt_end_tstz ASC) AS et_min_rank
                                    FROM alert.epis_triage et_min
                                    JOIN (SELECT id_episode
                                           FROM alert.episode
                                          WHERE flg_status != 'C'
                                            AND id_epis_type = 2
                                            AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY')) e1
                                      ON et_min.id_episode = e1.id_episode) et_min
                    ON (et_min.id_episode = e.id_episode)
                -- retriagem
                  LEFT OUTER JOIN (SELECT /*+ use_nl(e1 et_max)*/
                                   et_max.id_triage_color AS et_max_id_triage_color,
                                   et_max.dt_begin_tstz AS et_max_dt_triage_begin,
                                   et_max.dt_end_tstz AS et_max_dt_triage_end,
                                   et_max.id_episode,
                                   et_max.id_professional,
                                   et_max.id_epis_triage id_epis_triage_max,
                                   rank() over(PARTITION BY et_max.id_episode ORDER BY et_max.dt_end_tstz DESC) AS et_max_rank
                                    FROM alert.epis_triage et_max
                                    JOIN (SELECT id_episode
                                           FROM alert.episode
                                          WHERE flg_status != 'C'
                                            AND id_epis_type = 2
                                            AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY')) e1
                                      ON et_max.id_episode = e1.id_episode) et_max
                    ON (et_max.id_episode = e.id_episode)
                -- primeira responsabilidade médica
                  LEFT OUTER JOIN (SELECT /*+ use_nl(e1 a)*/
                                   a.*, rank() over(PARTITION BY a.id_episode ORDER BY a.dt_request_tstz ASC) AS rank1
                                    FROM alert.epis_prof_resp a
                                    JOIN (SELECT id_episode
                                           FROM alert.episode
                                          WHERE flg_status != 'C'
                                            AND id_epis_type = 2
                                            AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY')) e1
                                      ON a.id_episode = e1.id_episode
                                   WHERE a.flg_status = 'F'
                                     AND a.flg_type = 'D') epr
                    ON (epr.id_episode = e.id_episode)
                -- ultima responsabilidade
                  LEFT OUTER JOIN (SELECT /*+ use_nl(e1 a)*/
                                   a.*, rank() over(PARTITION BY a.id_episode ORDER BY a.dt_request_tstz DESC) AS rank1
                                    FROM alert.epis_prof_resp a
                                    JOIN (SELECT id_episode
                                           FROM alert.episode
                                          WHERE flg_status != 'C'
                                            AND id_epis_type = 2
                                            AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY')) e1
                                      ON a.id_episode = e1.id_episode
                                   WHERE a.flg_status = 'F'
                                     AND a.flg_type = 'D') epr_actual
                    ON (epr_actual.id_episode = e.id_episode)
                -- primeiro transporte
                  LEFT OUTER JOIN (SELECT /*+ use_nl(e1 mov)*/
                                   mov.id_room_to,
                                   mov.id_episode,
                                   rank() over(PARTITION BY mov.id_episode ORDER BY mov.dt_begin_tstz ASC NULLS LAST, mov.dt_req_tstz ASC) AS mov_rank
                                    FROM alert.movement mov
                                    JOIN (SELECT id_episode
                                           FROM alert.episode
                                          WHERE flg_status != 'C'
                                            AND id_epis_type = 2
                                            AND dt_begin_tstz > current_timestamp - numtodsinterval(8, 'DAY')) e1
                                      ON mov.id_episode = e1.id_episode) mov
                    ON (mov.id_episode = e.id_episode)
                  JOIN alert.epis_ext_sys ees
                    ON (ees.id_episode = e.id_episode AND ees.id_institution = e.id_institution)
                  LEFT OUTER JOIN alert.professional p1
                    ON (p1.id_professional = epr.id_prof_to)
                  LEFT OUTER JOIN alert.prof_institution pi1
                    ON (pi1.id_professional = p1.id_professional AND pi1.id_institution = e.id_institution AND
                       pi1.flg_state = 'A' AND pi1.dt_end_tstz IS NULL)
                  JOIN alert_adtcod.pat_ext_sys pes
                    ON (pes.id_patient = e.id_patient AND pes.id_institution = e.id_institution)
                  JOIN alert_adtcod.clin_record crec
                    ON (crec.id_patient = e.id_patient AND crec.id_institution = e.id_institution)
                  JOIN room ra
                    ON ra.id_room = ei.id_room
                  JOIN department d
                    ON ra.id_department = d.id_department
                  LEFT OUTER JOIN alert.professional p2
                    ON (p2.id_professional = epr_actual.id_prof_to)
                  LEFT OUTER JOIN alert.prof_institution pi2
                    ON (pi2.id_professional = p2.id_professional AND pi2.id_institution = e.id_institution AND
                       pi2.flg_state = 'A' AND pi2.dt_end_tstz IS NULL)
                 WHERE (et_min.et_min_rank = 1 OR et_min.et_min_rank IS NULL)
                   AND (et_max.et_max_rank = 1 OR et_max.et_max_rank IS NULL)
                   AND (mov.mov_rank = 1 OR mov.mov_rank IS NULL)
                   AND (epr.rank1 = 1 OR epr.rank1 IS NULL)
                   AND (epr_actual.rank1 = 1 OR epr_actual.rank1 IS NULL)));
