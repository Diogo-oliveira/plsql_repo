CREATE OR REPLACE VIEW v_alert_notification AS
SELECT t.id_sys_alert_event,
       t.id_sys_alert,
       t.dt_record,
       t.id_language,
       t.id_patient,
       t.name,
       t.id_institution,
       t.id_episode,
       t.id_software,
       t.soft_name,
       t.id_professional,
       t.flg_sms,
       t.flg_email,
       t.flg_im,
       t.replace1,
       t.replace2,
       t.replace3,
       t.replace4,
       t.replace5,
       t.replace6,
       t.replace7,
       t.replace8,
       t.replace9,
       t.replace10
  FROM (SELECT san.id_sys_alert_event,
               san.id_sys_alert,
               san.dt_record,
               san.id_language,
               san.id_patient,
               p.name,
               sac.id_institution,
               san.id_episode,
               san.id_software,
               s.name soft_name,
               san.id_prof id_professional,
               sac.flg_sms,
               sac.flg_email,
               sac.flg_im,
               san.replace1,
               san.replace2,
               san.replace3,
               san.replace4,
               san.replace5,
               san.replace6,
               san.replace7,
               san.replace8,
               san.replace9,
               san.replace10,
               row_number() over(PARTITION BY san.id_sys_alert_event, san.id_prof ORDER BY sac.id_institution DESC) rn
          FROM sys_alert_notification san
         INNER JOIN sys_alert_config sac
            ON sac.id_sys_alert = san.id_sys_alert
           AND sac.id_profile_template =
               pk_prof_utils.get_prof_profile_template(profissional(san.id_prof,
                                                                    (SELECT e.id_institution
                                                                       FROM episode e
                                                                      WHERE e.id_episode = san.id_episode),
                                                                    san.id_software))
         INNER JOIN patient p
            ON p.id_patient = san.id_patient
         INNER JOIN software s
            ON s.id_software = san.id_software
         WHERE (sac.flg_sms = 'Y' OR sac.flg_email = 'Y' OR sac.flg_im = 'Y')) t
 WHERE rn = 1;
