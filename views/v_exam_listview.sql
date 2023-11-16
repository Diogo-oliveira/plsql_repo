CREATE OR REPLACE VIEW v_exam_listview AS
SELECT DISTINCT eea.id_exam_req,
                eea.id_exam_req_det,
                eea.id_exam,
                eea.flg_type,
                eea.id_exam_cat,
                eea.flg_status_req,
                eea.flg_status_det,
                eea.flg_referral,
                eea.flg_time,
                eea.flg_notes,
                eea.notes,
                dbms_lob.substr(eea.notes_patient, 3800) notes_patient,
                eea.notes_technician,
                eea.flg_doc,
                eea.flg_req_origin_module,
                eea.flg_relevant,
                eea.priority,
                eea.dt_req,
                eea.dt_pend_req,
                eea.dt_begin,
                (SELECT de.dt_emited
                   FROM doc_external de, exam_media_archive ema
                  WHERE de.id_doc_external = ema.id_doc_external
                    AND ema.id_exam_result = eea.id_exam_result
                    AND rownum = 1) dt_emited,
                eea.status_str,
                eea.status_msg,
                eea.status_icon,
                eea.status_flg,
                eea.id_exam_result,
                er.id_external_doc,
                ema.id_doc_external,
                to_char((SELECT COUNT(1)
                          FROM doc_image
                         WHERE id_doc_external = ema.id_doc_external
                           AND flg_status = 'A')) num_images,
                eea.id_exam_codification,
                eea.id_task_dependency,
                e.id_episode,
                eea.id_episode_origin,
                e.id_epis_type,
                e.id_visit,
                eea.id_patient,
                eea.id_prof_req,
                decode(eea.flg_status_det,
                       'R',
                       row_number()
                       over(ORDER BY decode(eea.flg_referral,
                                   NULL,
                                   (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 'EXAM_REQ_DET.FLG_STATUS',
                                                                 eea.flg_status_det)
                                      FROM dual),
                                   (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 'EXAM_REQ_DET.FLG_REFERRAL',
                                                                 eea.flg_referral)
                                      FROM dual)),
                            coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                       'D',
                       row_number()
                       over(ORDER BY decode(eea.flg_referral,
                                   NULL,
                                   (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 'EXAM_REQ_DET.FLG_STATUS',
                                                                 eea.flg_status_det)
                                      FROM dual),
                                   (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 'EXAM_REQ_DET.FLG_REFERRAL',
                                                                 eea.flg_referral)
                                      FROM dual)),
                            coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req)),
                       row_number()
                       over(ORDER BY decode(eea.flg_referral,
                                   NULL,
                                   (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 'EXAM_REQ_DET.FLG_STATUS',
                                                                 eea.flg_status_det)
                                      FROM dual),
                                   (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                                 'EXAM_REQ_DET.FLG_REFERRAL',
                                                                 eea.flg_referral)
                                      FROM dual)),
                            coalesce(eea.dt_pend_req, eea.dt_begin, eea.dt_req) DESC)) rank
  FROM exams_ea eea,
       (SELECT *
          FROM exam_result e
         WHERE e.flg_status != 'C') er,
       (SELECT *
          FROM (SELECT e.*, row_number() over(ORDER BY e.dt_last_update_tstz DESC NULLS FIRST) rn
                  FROM exam_media_archive e
                 WHERE e.flg_type = 'R')
         WHERE rn = 1) ema,
       episode e
 WHERE eea.id_patient = sys_context('ALERT_CONTEXT', 'i_patient')
   AND eea.flg_time != 'R'
   AND eea.flg_status_req != 'DF'
   AND ((eea.id_episode = e.id_episode AND eea.id_episode = sys_context('ALERT_CONTEXT', 'i_episode')) OR
       (eea.id_episode_origin = e.id_episode AND eea.id_episode_origin = sys_context('ALERT_CONTEXT', 'i_episode')) OR
       (nvl(eea.id_episode, eea.id_episode_origin) = e.id_episode AND nvl(eea.id_episode, 0) != sys_context('ALERT_CONTEXT', 'i_episode') AND
       nvl(eea.id_episode_origin, 0) != sys_context('ALERT_CONTEXT', 'i_episode')))
   AND eea.id_exam_result = er.id_exam_result(+)
   AND er.id_exam_result = ema.id_exam_result(+);
