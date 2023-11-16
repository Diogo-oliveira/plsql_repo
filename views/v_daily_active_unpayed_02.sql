CREATE OR REPLACE VIEW v_daily_active_unpayed_02 AS
WITH sys_config AS
 (SELECT 1                      rn,
         t.sys_lang             sys_lang,
         t.sys_prof_id          sys_prof_id,
         t.sys_prof_institution sys_prof_institution,
         t.sys_prof_software    sys_prof_software,
         t.sys_lprof            sys_lprof
    FROM (SELECT alert_context('l_lang') sys_lang,
                 profissional(alert_context('l_prof_id'),
                              alert_context('l_prof_institution'),
                              alert_context('l_prof_software')) sys_lprof,
                 alert_context('l_prof_id') sys_prof_id,
                 alert_context('l_prof_institution') sys_prof_institution,
                 alert_context('l_prof_software') sys_prof_software
            FROM dual) t)
SELECT sc.sys_lang             sys_lang,
       sc.sys_prof_id          sys_prof_id,
       sc.sys_prof_institution sys_prof_institution,
       sc.sys_prof_software    sys_prof_software,
       sc.sys_lprof            sys_lprof,
       d.currency,
       d.dt_admin_tstz,
       d.dt_med_tstz,
       d.flg_payment,
       d.flg_status_adm,
       d.id_discharge,
       d.price,
       e.dt_begin_tstz,
       e.id_episode,
       ei.dt_first_obs_tstz,
       ei.id_dep_clin_serv,
       ei.id_schedule          ei_id_schedule,
       p.name                  p_name,
       p.nick_name             p_nick_name,
       p1.name                 p1_name,
       p1.nick_name            p1_nick_name,
       pat.id_patient,
       pat.gender,
       sg.flg_contact_type,
       sp.dt_target_tstz,
       sp.flg_sched,
       sp.flg_state,
       sp.id_schedule          sp_id_schedule,
       sp.id_schedule_outp
  FROM schedule_outp sp
  JOIN sys_config sc
    ON sc.rn = 1
  JOIN sch_group sg
    ON sg.id_schedule = sp.id_schedule
  JOIN epis_info ei
    ON ei.id_schedule = sp.id_schedule
  JOIN prof_dep_clin_serv pdcs
    ON pdcs.id_dep_clin_serv = ei.id_dcs_requested
  LEFT JOIN professional p
    ON p.id_professional = ei.sch_prof_outp_id_prof
  LEFT JOIN professional p1
    ON p1.id_professional = ei.id_professional
  JOIN episode e
    ON e.id_episode = ei.id_episode
  JOIN clinical_service cs
    ON cs.id_clinical_service = e.id_cs_requested
  JOIN patient pat
    ON ei.id_patient = pat.id_patient
  LEFT JOIN discharge d
    ON d.id_episode = e.id_episode
 WHERE e.flg_status != 'C'
   AND (e.flg_status = 'I' AND d.flg_payment != 'Y')
   AND sp.id_software = sc.sys_prof_software
   AND ei.id_instit_requested = sc.sys_prof_institution
   AND pdcs.id_professional = sc.sys_prof_id
   AND pdcs.flg_status = 'S'
   AND d.dt_cancel_tstz IS NULL;
