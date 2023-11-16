CREATE OR REPLACE VIEW V_PHA_TRANSPORT AS
SELECT "ID_PATIENT",
       "ID_EPISODE",
       "GENDER",
       "DT_BIRTH",
       "DT_DECEASED",
       "AGE",
       "ID_TASK",
       "ID_PHA_DISPENSE",
       "ID_PHA_RETURN",
       "FLG_RETURN",
       "ID_STATUS",
       "PROD_LIST",
       "ID_WORKFLOW",
       "NUM_CLIN_RECORD"
  FROM (SELECT td.id_patient,
               td.id_episode,
               td.gender,
               td.dt_birth,
               td.dt_deceased,
               td.age,
               td.id_task,
               td.id_pha_dispense,
               NULL id_pha_return,
               td.flg_return,
               td.id_status,
               (SELECT (SELECT listagg((SELECT pk_api_pfh_in.get_product_desc(i_lang                => sys_context('ALERT_CONTEXT',
                                                                                                                  'i_lang'),
                                                                             i_prof                => profissional(sys_context('ALERT_CONTEXT',
                                                                                                                               'i_prof_id'),
                                                                                                                   sys_context('ALERT_CONTEXT',
                                                                                                                               'i_institution'),
                                                                                                                   sys_context('ALERT_CONTEXT',
                                                                                                                               'i_software')),
                                                                             i_id_product          => phadd1.id_product,
                                                                             i_id_product_supplier => phadd1.id_product_supplier,
                                                                             i_id_presc            => NULL)
                                         FROM dual),
                                       ' + ') within GROUP(ORDER BY id_product)
                          FROM v_disp_det phadd1
                         WHERE phadd1.id_pha_dispense = td.id_pha_dispense)
                  FROM dual) prod_list,
               td.id_workflow,
               td.num_clin_record
          FROM (SELECT phad.id_task,
                       phad.id_workflow,
                       pat.gender,
                       pat.dt_birth,
                       pat.dt_deceased,
                       pat.age,
                       phad.id_patient,
                       phad.id_episode,
                       phad.id_pha_dispense,
                       'N' "FLG_RETURN",
                       phad.id_status,
                       cr.num_clin_record
                  FROM v_pha_dispense phad
                  JOIN patient pat
                    ON pat.id_patient = phad.id_patient
                  JOIN episode epis
                    ON epis.id_episode = phad.id_episode
                  JOIN epis_info ei
                    ON ei.id_episode = epis.id_episode
                  LEFT JOIN clin_record cr
                    ON (cr.id_patient = phad.id_patient AND (cr.id_episode = epis.id_episode OR cr.id_episode IS NULL) AND
                       cr.id_institution = epis.id_institution AND cr.flg_status = 'A' AND rownum = 1)
                 WHERE (phad.id_status IN (523, 524) OR
                       (phad.id_status = 525 AND
                       pk_date_utils.get_timestamp_diff(i_timestamp_1 => current_timestamp,
                                                          i_timestamp_2 => nvl(phad.dt_last_update, phad.dt_create)) < 1))
                   AND (sys_context('ALERT_CONTEXT', 'i_software') = 20 OR
                       sys_context('ALERT_CONTEXT', 'i_software') = ei.id_software)
                   AND epis.flg_status <> 'C'
                   AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')) td
        
        UNION ALL
        SELECT tr.id_patient,
               tr.id_episode,
               tr.gender,
               tr.dt_birth,
               tr.dt_deceased,
               tr.age,
               tr.id_task,
               tr.id_pha_dispense,
               tr.id_pha_return,
               tr.flg_return,
               tr.id_status,
               (SELECT (SELECT listagg((SELECT pk_api_pfh_in.get_product_desc(i_lang                => sys_context('ALERT_CONTEXT',
                                                                                                                  'i_lang'),
                                                                             i_prof                => profissional(sys_context('ALERT_CONTEXT',
                                                                                                                               'i_prof_id'),
                                                                                                                   sys_context('ALERT_CONTEXT',
                                                                                                                               'i_institution'),
                                                                                                                   sys_context('ALERT_CONTEXT',
                                                                                                                               'i_software')),
                                                                             i_id_product          => phard1.id_product,
                                                                             i_id_product_supplier => phard1.id_product_supplier,
                                                                             i_id_presc            => NULL)
                                         FROM dual),
                                       ' + ') within GROUP(ORDER BY id_product)
                          FROM v_pha_return_det phard1
                         WHERE phard1.id_pha_return = tr.id_pha_return
                           AND rownum = 1)
                  FROM dual) prod_list,
               tr.id_workflow,
               tr.num_clin_record
          FROM (SELECT phr.id_task,
                       phr.id_workflow,
                       pat.gender,
                       pat.dt_birth,
                       pat.dt_deceased,
                       pat.age,
                       phr.id_pha_return,
                       phr.id_patient,
                       phr.id_episode,
                       phr.id_pha_dispense,
                       'Y' "FLG_RETURN",
                       phr.id_status,
                       cr.num_clin_record
                  FROM v_pha_return phr
                  JOIN patient pat
                    ON pat.id_patient = phr.id_patient
                  JOIN episode epis
                    ON epis.id_episode = phr.id_episode
                  JOIN epis_info ei
                    ON ei.id_episode = epis.id_episode
                  LEFT JOIN clin_record cr
                    ON (cr.id_patient = phr.id_patient AND (cr.id_episode = epis.id_episode OR cr.id_episode IS NULL) AND
                       cr.id_institution = epis.id_institution AND cr.flg_status = 'A' AND rownum = 1)
                 WHERE (phr.id_status IN (523, 524) OR
                       (phr.id_status = 525 AND
                       pk_date_utils.get_timestamp_diff(i_timestamp_1 => current_timestamp,
                                                          i_timestamp_2 => phr.dt_last_update) < 1))
                   AND epis.flg_status <> 'C'
                   AND (sys_context('ALERT_CONTEXT', 'i_software') = 20 OR
                       sys_context('ALERT_CONTEXT', 'i_software') = ei.id_software)
                   AND epis.id_institution = sys_context('ALERT_CONTEXT', 'i_institution')) tr) t
 WHERE t.prod_list IS NOT NULL;
