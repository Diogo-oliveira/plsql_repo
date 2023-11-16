CREATE OR REPLACE VIEW v_lab_hand_off AS
SELECT *
  FROM (SELECT 'A' type_rec,
               ard.id_analysis_req_det,
               ais.id_exam_cat,
               pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                              'EXAM_CAT.CODE_EXAM_CAT.' || ard.id_exam_cat) desc_dep,
               decode(upper(pk_lab_tests_api_db.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                      profissional(sys_context('ALERT_CONTEXT',
                                                                                               'ID_PROFESSIONAL'),
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_INSTITUTION'),
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_SOFTWARE')),
                                                                      'A',
                                                                      'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                                      NULL)),
                      upper(pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                           'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis)),
                      pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                     'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis),
                      pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                     'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis) || ' (' ||
                      pk_lab_tests_api_db.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                profissional(sys_context('ALERT_CONTEXT',
                                                                                         'ID_PROFESSIONAL'),
                                                                             sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                             sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                                'A',
                                                                'ANALYSIS.CODE_ANALYSIS.' || ard.id_analysis,
                                                                NULL) || ')') desc_param,
               --requisição
               decode(ard.flg_time_harvest,
                      'E',
                      pk_sysdomain.get_domain('ANALYSIS_REQ.FLG_TIME',
                                              ard.flg_time_harvest,
                                              sys_context('ALERT_CONTEXT', 'ID_LANG')) ||
                      decode(pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                         ard.dt_target_tstz,
                                                         sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                         sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                             NULL,
                             NULL,
                             ' (') ||
                      pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                  ard.dt_target_tstz,
                                                  sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                  sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) ||
                      decode(pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                         ard.dt_target_tstz,
                                                         sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                         sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                             NULL,
                             NULL,
                             ')'),
                      pk_sysdomain.get_domain('ANALYSIS_REQ.FLG_TIME',
                                              ard.flg_time_harvest,
                                              sys_context('ALERT_CONTEXT', 'ID_LANG'))) desc_time,
               pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                           ard.dt_target_tstz,
                                           sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                           sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) date_begin,
               pk_tools.get_prof_description(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                             profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                          sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                          sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                             ar.id_prof_writes,
                                             ar.dt_req_tstz,
                                             ar.id_prev_episode) prof_req,
               pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                           ar.dt_req_tstz,
                                           sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                           sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) date_order,
               pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                              'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type) desc_samp_type,
               pk_sysdomain.get_domain('ANALYSIS.YES_NO', ard.flg_col_inst, sys_context('ALERT_CONTEXT', 'ID_LANG')) desc_collect,
               cso.desc_order_type order_type_desc,
               pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_URGENCY',
                                       ard.flg_urgency,
                                       sys_context('ALERT_CONTEXT', 'ID_LANG')) desc_urgency,
               pk_sysdomain.get_domain('ANALYSIS.YES_NO', ard.flg_fasting, sys_context('ALERT_CONTEXT', 'ID_LANG')) desc_fasting,
               ard.notes,
               ard.notes_tech,
               ard.flg_status,
               pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                     'ANALYSIS_REQ_DET.FLG_STATUS',
                                     ard.flg_status) rank_type,
               pk_diagnosis.concat_diag(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                        NULL,
                                        ard.id_analysis_req_det,
                                        NULL,
                                        profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                     sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                     sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) desc_diagnosis,
               decode(ard.flg_referral,
                      'R',
                      pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_REFERRAL',
                                              ard.flg_referral,
                                              sys_context('ALERT_CONTEXT', 'ID_LANG')),
                      'S',
                      pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_REFERRAL',
                                              ard.flg_referral,
                                              sys_context('ALERT_CONTEXT', 'ID_LANG')),
                      pk_sysdomain.get_domain('ANALYSIS_REQ_DET.FLG_STATUS',
                                              ard.flg_status,
                                              sys_context('ALERT_CONTEXT', 'ID_LANG'))) desc_status,
               pk_tools.get_prof_description(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                             profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                          sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                          sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                             ard.id_prof_cancel,
                                             ard.dt_cancel_tstz,
                                             ar.id_prev_episode) prof_cancel_desc,
               pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                           ard.dt_cancel_tstz,
                                           sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                           sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) cancel_date,
               ard.notes_cancel,
               --colheita
               h.id_harvest,
               h.num_recipient,
               pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                              'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || ah.id_sample_recipient) recipient,
               pk_sysdomain.get_domain('HARVEST.FLG_STATUS', h.flg_status, sys_context('ALERT_CONTEXT', 'ID_LANG')) harv_status,
               h.notes harvest_notes,
               pk_prof_utils.get_name_signature(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                             sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                             sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                h.id_prof_harvest) harvest_prof,
               pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                           h.dt_harvest_tstz,
                                           sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                           sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) harvest_date,
               --resultado
               NULL dt_analysis_result_par,
               '' desc_analysis_result,
               NULL desc_unit_measure,
               NULL ref_val,
               NULL abbrev_lab,
               NULL desc_lab,
               NULL intf_notes,
               NULL abnorm,
               NULL desc_abnormality,
               ares.notes notes_result,
               NULL desc_laboratory,
               pk_prof_utils.get_name_signature(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                             sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                             sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                ares.id_professional) nick_name,
               pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                           ares.dt_analysis_result_tstz,
                                           sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                           sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) dt_result,
               ard.id_analysis,
               NULL id_analysis_parameter,
               ais.rank rank_cat_analysis,
               NULL rank_parameter,
               ares.dt_analysis_result_tstz,
               ard.flg_referral
          FROM analysis_req_det ard,
               analysis_req ar,
               TABLE(pk_co_sign_api.tf_co_sign_task_hist_info(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                              profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                           sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                           sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                              sys_context('ALERT_CONTEXT', 'ID_EPISODE'),
                                                              NULL)) cso,
               harvest h,
               analysis_harvest ah,
               analysis_result ares,
               analysis_instit_soft ais
         WHERE (sys_context('ALERT_CONTEXT', 'ID_EPISODE') = ar.id_prev_episode OR
               (sys_context('ALERT_CONTEXT', 'ID_EPISODE') = ar.id_episode AND ar.id_prev_episode IS NULL))
           AND ard.id_analysis_req = ar.id_analysis_req
           AND ard.id_co_sign_order = cso.id_co_sign_hist(+)
           AND ard.id_analysis_req_det = ah.id_analysis_req_det(+)
           AND ah.id_harvest = h.id_harvest(+)
           AND ard.id_analysis_req_det = ares.id_analysis_req_det(+)
           AND ares.flg_orig_analysis IS NULL
              -- NAO MOSTRA OS REGISTOS DAS ANALISES SEM RESULTADO, ESPECIFICAMENTE PARA O HOSPITAL DE BEJA    
           AND (ard.flg_status != 'C' AND ar.flg_status != 'C' AND (h.flg_status IS NULL OR h.flg_status != 'C') AND
               (ares.flg_status IS NULL OR ares.flg_status != 'C'))
           AND ard.id_analysis = ais.id_analysis
           AND ard.id_sample_type = ais.id_sample_type
           AND ais.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND ais.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND ais.flg_available = 'Y')
 ORDER BY rank_cat_analysis,
          rank_parameter,
          id_exam_cat,
          id_analysis_req_det,
          type_rec,
          date_order,
          nvl(id_analysis_parameter, 0),
          nvl2(dt_analysis_result_par, 1, 2),
          dt_analysis_result_par,
          rank_type;
