CREATE OR REPLACE VIEW v_exams_hand_off AS
SELECT DISTINCT e.flg_type,
                er.id_exam_req,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            er.dt_req_tstz,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) dt,
                e.id_exam,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            er.dt_req_tstz,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) dt_req,
                erd.flg_status,
                pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_STATUS',
                                        erd.flg_status,
                                        sys_context('ALERT_CONTEXT', 'ID_LANG')) desc_status,
                pk_sysdomain.get_domain('EXAM_REQ.FLG_TIME', er.flg_time, sys_context('ALERT_CONTEXT', 'ID_LANG')) desc_time,
                decode(er.flg_time,
                       'N',
                       pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001'),
                       'B',
                       nvl(pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                       er.dt_begin_tstz,
                                                       sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                       sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                           pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001')),
                       pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                   nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                   sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                   sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) dt_begin,
                decode(er.flg_time,
                       'N',
                       NULL,
                       'B',
                       nvl(pk_date_utils.dt_chr_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                    er.dt_begin_tstz,
                                                    sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                    sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                           NULL),
                       pk_date_utils.dt_chr_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) date_target,
                decode(er.flg_time,
                       'N',
                       pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001'),
                       'B',
                       nvl(pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                            er.dt_begin_tstz,
                                                            sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                            sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                           pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001')),
                       pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                        nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                        sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                        sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) hour_target,
                decode(er.flg_time,
                       'B',
                       pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                   er.dt_req_tstz,
                                                   alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))),
                       'E',
                       pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                   nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                   alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')))) dt_target,
                pk_exams_api_db.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                      alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                         sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                         sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                      e.code_exam,
                                                      NULL) exam,
                er.id_prof_req,
                prof.nick_name prof_req,
                pk_date_utils.dt_chr_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                         er.dt_req_tstz,
                                         alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                            sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                            sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) date_req,
                pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                 er.dt_req_tstz,
                                                 sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                 sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) hour_req,
                pk_date_utils.to_char_insttimezone(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                   nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                   'YYYYMMDDHH24MISS') dt_ord1,
                pk_date_utils.to_char_insttimezone(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                   er.dt_req_tstz,
                                                   'YYYYMMDDHH24MISS') dt_ord2,
                pk_diagnosis.concat_diag(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                         erd.id_exam_req_det,
                                         NULL,
                                         NULL,
                                         alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                            sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                            sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) desc_diagnosis,
                /*DESC_STAT*/
                decode(erd.flg_referral,
                       'R',
                       pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            'EXAM_REQ_DET.FLG_REFERRAL',
                                            erd.flg_referral),
                       'S',
                       pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            'EXAM_REQ_DET.FLG_REFERRAL',
                                            erd.flg_referral),
                       decode(er.id_episode_origin,
                              NULL,
                              decode(erd.flg_status,
                                     'F',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'F'),
                                     'C',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'C'),
                                     'L',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'L'),
                                     'T',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'T'),
                                     'M',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'M'),
                                     'E',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'E'),
                                     'R',
                                     decode(er.dt_pend_req_tstz,
                                            NULL,
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              er.dt_begin_tstz),
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              er.dt_pend_req_tstz)),
                                     decode(er.flg_time,
                                            'N',
                                            pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                            decode(er.dt_begin_tstz,
                                                   NULL,
                                                   pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                          'ICON_T056'),
                                                   pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                                     er.dt_begin_tstz)))),
                              decode(erd.flg_status,
                                     'F',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'F'),
                                     'C',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'C'),
                                     'L',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'L'),
                                     'T',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'T'),
                                     'M',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'M'),
                                     'E',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'E'),
                                     'R',
                                     pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                     'D',
                                     decode(er.dt_begin_tstz,
                                            NULL,
                                            pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              nvl(er.dt_begin_tstz, er.dt_req_tstz))),
                                     decode(er.flg_time,
                                            'N',
                                            pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              nvl(er.dt_begin_tstz, er.dt_req_tstz)))))) desc_stat,
                pk_tools.get_prof_nick_name(sys_context('ALERT_CONTEXT', 'ID_LANG'), erd.id_prof_performed) prof_performed,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            erd.start_time,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) start_time_send,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            erd.end_time,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) end_time_send,
                erd.end_time
  FROM exam_req er,
       episode epi,
       exam_req_det erd,
       exam e,
       professional prof,
       exam_result ert,
       (SELECT *
          FROM exam_dep_clin_serv
         WHERE flg_type IN ('P', 'C')
           AND id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) edcs
 WHERE erd.id_exam_req = er.id_exam_req
   AND er.id_episode = sys_context('ALERT_CONTEXT', 'ID_EPISODE')
   AND epi.id_episode = er.id_episode
   AND e.id_exam = erd.id_exam
   AND prof.id_professional = er.id_prof_req
   AND ert.id_exam_req_det = erd.id_exam_req_det
   AND ert.flg_status != 'C' --pk_exam_constant.g_exam_result_cancel
   AND ert.dt_exam_result_tstz = (SELECT MAX(x.dt_exam_result_tstz)
                                    FROM exam_result x
                                   WHERE id_exam_req_det = erd.id_exam_req_det
                                     AND x.flg_status != 'C') --pk_exam_constant.g_exam_result_cancel
   AND edcs.id_exam(+) = e.id_exam
UNION ALL
-- Req. s/ resultados
SELECT DISTINCT e.flg_type,
                er.id_exam_req,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            er.dt_req_tstz,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) dt,
                e.id_exam,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            er.dt_req_tstz,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) dt_req,
                erd.flg_status,
                pk_sysdomain.get_domain('EXAM_REQ_DET.FLG_STATUS',
                                        erd.flg_status,
                                        sys_context('ALERT_CONTEXT', 'ID_LANG')) desc_status,
                pk_sysdomain.get_domain('EXAM_REQ.FLG_TIME', er.flg_time, sys_context('ALERT_CONTEXT', 'ID_LANG')) desc_time,
                decode(er.flg_time,
                       'N',
                       pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001'),
                       'B',
                       nvl(pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                       er.dt_begin_tstz,
                                                       sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                       sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                           pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001')),
                       pk_date_utils.date_char_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                   nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                   sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                   sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) dt_begin,
                decode(er.flg_time,
                       'N',
                       NULL,
                       'B',
                       decode(er.dt_begin_tstz,
                              NULL,
                              decode(er.dt_schedule_tstz,
                                     NULL,
                                     NULL,
                                     pk_date_utils.dt_chr_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                              er.dt_schedule_tstz,
                                                              sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                              sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) || ' ' ||
                                     pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M002')),
                              pk_date_utils.dt_chr_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                       er.dt_begin_tstz,
                                                       sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                       sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))),
                       pk_date_utils.dt_chr_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) date_target,
                decode(er.flg_time,
                       'N',
                       pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001'),
                       'B',
                       decode(er.dt_begin_tstz,
                              NULL,
                              nvl(pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                   er.dt_schedule_tstz,
                                                                   sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                   sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                  pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'EXAM_REQ_M001')),
                              pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                               er.dt_begin_tstz,
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))),
                       pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                        nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                        sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                        sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) hour_target,
                decode(er.flg_time,
                       'B',
                       pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                   er.dt_req_tstz,
                                                   alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))),
                       'E',
                       pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                   nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                   alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')))) dt_target,
                pk_exams_api_db.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                      alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                         sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                         sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                      e.code_exam,
                                                      NULL) exam,
                er.id_prof_req,
                prof.nick_name prof_req,
                pk_date_utils.dt_chr_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                         er.dt_req_tstz,
                                         alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                            sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                            sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) date_req,
                pk_date_utils.date_char_hour_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                 er.dt_req_tstz,
                                                 sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                 sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) hour_req,
                pk_date_utils.to_char_insttimezone(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                   nvl(er.dt_begin_tstz, er.dt_req_tstz),
                                                   'YYYMMDDHH24MISS') dt_ord1,
                pk_date_utils.to_char_insttimezone(alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                      sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                   er.dt_req_tstz,
                                                   'YYYMMDDHH24MISS') dt_ord2,
                pk_diagnosis.concat_diag(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                         erd.id_exam_req_det,
                                         NULL,
                                         NULL,
                                         alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                            sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                            sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) desc_diagnosis, -- SS 2007/02/06
                /*DESC_STAT*/
                decode(erd.flg_referral,
                       'R',
                       pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            'EXAM_REQ_DET.FLG_REFERRAL',
                                            erd.flg_referral),
                       'S',
                       pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            'EXAM_REQ_DET.FLG_REFERRAL',
                                            erd.flg_referral),
                       decode(er.id_episode_origin,
                              NULL,
                              decode(erd.flg_status,
                                     'PA',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'PA'),
                                     'A',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'A'),
                                     'F',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'F'),
                                     'C',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'C'),
                                     'L',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'L'),
                                     'T',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'T'),
                                     'M',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'M'),
                                     'E',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'E'),
                                     'R',
                                     decode(er.dt_pend_req_tstz,
                                            NULL,
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              er.dt_begin_tstz),
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              er.dt_pend_req_tstz)),
                                     decode(er.flg_time,
                                            'N',
                                            pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                            decode(er.dt_begin_tstz,
                                                   NULL,
                                                   pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                        'EXAM_REQ_DET.FLG_STATUS',
                                                                        'PA'),
                                                   pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                                     nvl(er.dt_pend_req_tstz,
                                                                                         er.dt_begin_tstz))))),
                              decode(erd.flg_status,
                                     'PA',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'PA'),
                                     'A',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'A'),
                                     'F',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'F'),
                                     'C',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'C'),
                                     'L',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'L'),
                                     'T',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'T'),
                                     'M',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'M'),
                                     'E',
                                     pk_sysdomain.get_img(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                          'EXAM_REQ_DET.FLG_STATUS',
                                                          'E'),
                                     'R',
                                     decode(er.dt_begin_tstz,
                                            NULL,
                                            pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              nvl(er.dt_pend_req_tstz, er.dt_begin_tstz))),
                                     'D',
                                     decode(er.dt_begin_tstz,
                                            NULL,
                                            pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              nvl(er.dt_begin_tstz, er.dt_req_tstz))),
                                     decode(er.flg_time,
                                            'N',
                                            pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANG'), 'ICON_T056'),
                                            pk_date_utils.get_elapsed_abs_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                                                              nvl(er.dt_begin_tstz, er.dt_req_tstz)))))) desc_stat,
                pk_tools.get_prof_nick_name(sys_context('ALERT_CONTEXT', 'ID_LANG'), erd.id_prof_performed) prof_performed,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            erd.start_time,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) start_time_send,
                pk_date_utils.date_send_tsz(sys_context('ALERT_CONTEXT', 'ID_LANG'),
                                            erd.end_time,
                                            alert.profissional(sys_context('ALERT_CONTEXT', 'ID_PROFESSIONAL'),
                                                               sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                               sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))) end_time_send,
                erd.end_time
  FROM exam_req er,
       episode epi,
       exam_req_det erd,
       exam e,
       professional prof,
       (SELECT *
          FROM exam_dep_clin_serv
         WHERE flg_type IN ('P', 'C')
           AND id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) edcs
 WHERE erd.id_exam_req = er.id_exam_req
   AND er.id_episode = sys_context('ALERT_CONTEXT', 'ID_EPISODE')
   AND epi.id_episode = er.id_episode
   AND e.id_exam = erd.id_exam
   AND prof.id_professional = er.id_prof_req
   AND NOT EXISTS (SELECT 'X'
          FROM exam_result x
         WHERE x.id_exam_req_det = erd.id_exam_req_det
           AND x.flg_status != 'C') --pk_exam_constant.g_exam_result_cancel
   AND edcs.id_exam(+) = e.id_exam
   AND erd.flg_status != 'C'
 ORDER BY dt DESC;