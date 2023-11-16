CREATE OR REPLACE   VIEW V_SYS_ALERT_332 AS
WITH aux_sql AS
 (SELECT 332 id_sys_alert,
         pk_message.get_message(sys_lang, 'SYS_ALERT_332_T001') sys_msg,
         pk_message.get_message(sys_lang, 'ALERT_LIST_T003') sys_list_t003,
         pk_hhc_core.is_case_manager(i_lang => sys_lang, i_prof => sys_lprof) sys_is_case_manager,
         'A' k_sch_status_approved,
         312 k_hhc_software,
         x01.sys_lprof,
         x01.sys_lang,
         x01.sys_prof_id,
         x01.sys_institution,
         x01.sys_software,
         CAST(trunc(current_timestamp) AS TIMESTAMP WITH LOCAL TIME ZONE) dt_limit
    FROM (SELECT profissional(alert_context('i_prof'), alert_context('i_institution'), alert_context('i_software')) sys_lprof,
                 alert_context('i_lang') sys_lang,
                 alert_context('i_prof') sys_prof_id,
                 alert_context('i_institution') sys_institution,
                 alert_context('i_software') sys_software
            FROM dual) x01)
SELECT /*+ opt_param('_OPTIMIZER_USE_FEEDBACK', 'FALSE') */
 v.id_sys_alert_event id_sys_alert_det,
 v.id_record id_reg,
 hhc.id_episode id_episode,
 v.id_institution id_institution,
 aux.sys_prof_id id_prof,
 pk_date_utils.to_char_insttimezone(aux.sys_lprof, v.dt_record, 'YYYYMMDDHH24MISS') dt_req,
 decode(instr(pk_date_utils.get_elapsed_sysdate_tsz(aux.sys_lang, v.dt_record), ':'),
        0,
        pk_date_utils.get_elapsed_sysdate_tsz(aux.sys_lang, v.dt_record),
        pk_date_utils.get_elapsed_sysdate_tsz(aux.sys_lang, v.dt_record) || chr(32) || aux.sys_list_t003) TIME,
 REPLACE(aux.sys_msg,
         '@1',
         REPLACE(pk_hhc_core.get_hhc_professional(i_lang        => aux.sys_lang,
                                                  i_prof        => aux.sys_lprof,
                                                  i_id_schedule => s.id_schedule),
                 '  ,  ',
                 ', ')) message,
 s.id_room,
 vis.id_patient id_patient,
 pk_patient.get_pat_name(aux.sys_lang, aux.sys_lprof, vis.id_patient, NULL) name_pat,
 pk_adt.get_pat_non_disc_options(aux.sys_lang, aux.sys_lprof, pat.id_patient) pat_ndo,
 pk_adt.get_pat_non_disclosure_icon(aux.sys_lang, aux.sys_lprof, pat.id_patient) pat_nd_icon,
 pk_patphoto.get_pat_photo(aux.sys_lang, aux.sys_lprof, pat.id_patient, v.id_episode, s.id_schedule) photo,
 pat.gender,
 pk_patient.get_pat_age(aux.sys_lang, pat.dt_birth, pat.age, aux.sys_institution, aux.sys_software) pat_age,
 (SELECT coalesce(r.desc_room_abbreviation,
                  pk_translation.get_translation(aux.sys_lang, r.code_abbreviation),
                  r.desc_room,
                  pk_translation.get_translation(aux.sys_lang, r.code_room))
    FROM dual) desc_room,
 pk_date_utils.get_elapsed_tsz(aux.sys_lang, s.dt_cancel_tstz, current_timestamp) date_send,
 NULL desc_epis_anamnesis,
 NULL acuity,
 NULL rank_acuity,
 null id_schedule,
 --s.id_schedule,
 pk_alerts.get_alerts_shortcut(aux.sys_lprof, v.id_sys_alert) id_sys_shortcut,
 v.id_record id_reg_det,
 v.id_sys_alert,
 NULL dt_first_obs_tstz,
 NULL fast_track_icon,
 NULL fast_track_color,
 'A' fast_track_status,
 NULL esi_level,
 pk_patient.get_pat_name_to_sort(aux.sys_lang, aux.sys_lprof, pat.id_patient, NULL) name_pat_sort,
 table_varchar() resp_icons,
 id_prof_order
  FROM sys_alert_event v
  JOIN aux_sql aux
    ON v.id_sys_alert = aux.id_sys_alert
  JOIN sys_alert sa
    ON sa.id_sys_alert = v.id_sys_alert
  JOIN schedule s
    ON s.id_schedule = v.id_record
  JOIN epis_info ei
    ON s.id_schedule = ei.id_schedule
  LEFT JOIN room r
    ON r.id_room = ei.id_room
  JOIN episode e
    ON e.id_episode = ei.id_episode
  JOIN episode hhc
    ON hhc.id_episode = e.id_prev_episode
  JOIN epis_hhc_req eh
    ON eh.id_epis_hhc = hhc.id_episode
  JOIN visit vis
    ON vis.id_visit = e.id_visit
  JOIN patient pat
    ON pat.id_patient = vis.id_patient
 WHERE 0 = 0
   AND v.id_institution = aux.sys_institution
   AND v.id_software = aux.sys_software
   AND v.flg_visible = 'Y'
   AND s.dt_begin_tstz > aux.dt_limit
   AND s.flg_status = aux.k_sch_status_approved
   AND e.flg_ehr = 'S'
   AND aux.sys_is_case_manager = 'Y'
   AND ( eh.id_prof_manager = aux.sys_prof_id or s.id_prof_schedules = aux.sys_prof_id )
   AND aux.sys_software = aux.k_hhc_software
   AND NOT EXISTS
 (SELECT 1
          FROM sys_alert_read sar
         WHERE sar.id_sys_alert_event = v.id_sys_alert_event
           AND sar.id_professional = aux.sys_prof_id
           AND pk_alerts.get_config_flg_read(aux.sys_lang, aux.sys_lprof, v.id_sys_alert, NULL) = 'N')
  and pk_alerts.check_if_alert_expired( i_prof => aux.sys_lprof
                    , i_dt_creation  => v.dt_creation
                    , i_id_sys_alert => v.id_sys_alert ) > 0  		   
;
