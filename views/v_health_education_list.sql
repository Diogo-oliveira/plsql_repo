CREATE OR REPLACE VIEW V_HEALTH_EDUCATION_LIST AS
SELECT ntr.id_nurse_tea_req,
       ntr.id_nurse_tea_topic,
       ntr.desc_topic_aux,
       ntt.code_nurse_tea_topic,
       nts.code_nurse_tea_subject,
       ntt.id_nurse_tea_topic id_nurse_tea_topic_ntt,
       nts.id_nurse_tea_subject,
       ntr.notes_req,
       ntr.notes_close,
       ntr.flg_status,
       ntr.dt_begin_tstz,
       ntr.flg_time,
       ntr.id_prof_req,
       ntr.status_str,
       ntr.status_msg,
       ntr.status_icon,
       ntr.status_flg,
       ntr.id_context,
       sys_context('ALERT_CONTEXT', 'i_lang') i_lang,
       sys_context('ALERT_CONTEXT', 'i_prof_id') i_prof_id,
       sys_context('ALERT_CONTEXT', 'i_prof_institution') i_prof_institution,
       sys_context('ALERT_CONTEXT', 'i_prof_software') i_prof_software
  FROM nurse_tea_req ntr
  LEFT JOIN nurse_tea_topic ntt
    ON ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
  LEFT JOIN nurse_tea_subject nts
    ON nts.id_nurse_tea_subject = ntt.id_nurse_tea_subject
  JOIN professional p
    ON p.id_professional = ntr.id_prof_req
  JOIN episode e
    ON e.id_episode = ntr.id_episode
 WHERE ntr.flg_status NOT IN ('Z', 'PD')
   AND e.id_episode IN
       (SELECT column_value
          FROM TABLE(CAST(pk_string_utils.str_split(sys_context('ALERT_CONTEXT', 'l_episodes'), ';') AS table_varchar)));
