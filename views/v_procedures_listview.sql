CREATE OR REPLACE VIEW v_procedures_listview AS
SELECT t.*,
       decode(t.flg_status_det,
              'R',
              row_number()
              over(ORDER BY decode(t.flg_referral,
                          NULL,
                          (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                        t.flg_status_det)
                             FROM dual),
                          (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                        'INTERV_PRESC_DET.FLG_REFERRAL',
                                                        t.flg_referral)
                             FROM dual)),
                   nvl(t.dt_plan_tstz, t.dt_begin_req),
                   pk_procedures_utils.get_alias_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                          sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                             'INTERVENTION.CODE_INTERVENTION.' || t.id_intervention,
                                                             NULL)),
              row_number()
              over(ORDER BY decode(t.flg_referral,
                          NULL,
                          (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                        'INTERV_PRESC_DET.FLG_STATUS',
                                                        t.flg_status_det)
                             FROM dual),
                          (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                        'INTERV_PRESC_DET.FLG_REFERRAL',
                                                        t.flg_referral)
                             FROM dual)),
                   nvl(t.dt_plan_tstz, t.dt_begin_req) DESC,
                   pk_procedures_utils.get_alias_translation(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                             profissional(sys_context('ALERT_CONTEXT', 'i_prof_id'),
                                                                          sys_context('ALERT_CONTEXT', 'i_prof_institution'),
                                                                          sys_context('ALERT_CONTEXT', 'i_prof_software')),
                                                             'INTERVENTION.CODE_INTERVENTION.' || t.id_intervention,
                                                             NULL))) rank
  FROM (SELECT pea.id_interv_prescription,
               pea.id_interv_presc_det,
               pea.id_intervention,
               ipd.id_presc_plan_task,
               pea.flg_status_det,
               pea.flg_referral,
               pea.flg_laterality,
               pea.flg_notes,
               pea.notes,
               pea.notes_cancel,
               pea.flg_doc,
               pea.flg_req_origin_module,
               pea.status_str,
               pea.status_msg,
               pea.status_icon,
               pea.status_flg,
               pea.flg_prty,
               pea.id_order_recurrence,
               pea.id_interv_codification,
               pea.id_task_dependency,
               e.id_episode,
               pea.id_episode_origin,
               e.id_epis_type,
               e.id_visit,
               pea.id_patient,
               pea.flg_time,
               ipp.dt_plan_tstz,
               pea.dt_begin_req
          FROM procedures_ea pea,
               interv_presc_det ipd,
               (SELECT *
                  FROM interv_presc_plan
                 WHERE flg_status IN ('R', 'D')) ipp,
               episode e
         WHERE pea.id_patient = sys_context('ALERT_CONTEXT', 'i_patient')
           AND ((pea.id_episode = e.id_episode AND pea.id_episode = sys_context('ALERT_CONTEXT', 'i_episode')) OR
               (pea.id_episode_origin = e.id_episode AND
               pea.id_episode_origin = sys_context('ALERT_CONTEXT', 'i_episode')) OR
               (pea.id_episode = e.id_episode AND nvl(pea.id_episode, 0) != sys_context('ALERT_CONTEXT', 'i_episode') AND
               nvl(pea.id_episode_origin, 0) != sys_context('ALERT_CONTEXT', 'i_episode')))
           AND pea.flg_status_det != 'Z'
           AND pea.flg_time NOT IN ('A', 'H')
           AND pea.id_interv_presc_det = ipd.id_interv_presc_det
           AND pea.id_interv_presc_det = ipp.id_interv_presc_det(+)
        UNION ALL
        SELECT pea.id_interv_prescription,
               pea.id_interv_presc_det,
               pea.id_intervention,
               ipd.id_presc_plan_task,
               pea.flg_status_det,
               pea.flg_referral,
               pea.flg_laterality,
               pea.flg_notes,
               pea.notes,
               pea.notes_cancel,
               pea.flg_doc,
               pea.flg_req_origin_module,
               pea.status_str,
               pea.status_msg,
               pea.status_icon,
               pea.status_flg,
               pea.flg_prty,
               pea.id_order_recurrence,
               pea.id_interv_codification,
               pea.id_task_dependency,
               pea.id_episode,
               pea.id_episode_origin,
               pk_episode.get_epis_type(sys_context('ALERT_CONTEXT', 'i_lang'),
                                        nvl(pea.id_episode, pea.id_episode_origin)) id_epis_type,
               pk_episode.get_id_visit(pea.id_episode) id_visit,
               --e.id_visit,
               pea.id_patient,
               pea.flg_time,
               ipp.dt_plan_tstz,
               pea.dt_begin_req
          FROM procedures_ea pea,
               interv_presc_det ipd,
               (SELECT *
                  FROM interv_presc_plan
                 WHERE flg_status IN ('R', 'D')) ipp
         WHERE pea.id_patient = sys_context('ALERT_CONTEXT', 'i_patient')
           AND pea.flg_status_det != 'Z'
           AND pea.flg_time IN ('A', 'H')
           AND pea.id_interv_presc_det = ipd.id_interv_presc_det
           AND pea.id_interv_presc_det = ipp.id_interv_presc_det(+)) t;
