CREATE OR REPLACE VIEW V_BP_WITNESS_BY AS
SELECT p.id_professional, p.name, ui.login
  FROM professional p
  JOIN ab_user_info ui
    ON (ui.id_ab_user_info = p.id_professional)
 WHERE ui.login IS NOT NULL
   AND sys_context('ALERT_CONTEXT', 'i_scenario') = 1
   AND EXISTS (SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.id_profile_template IN (47, 22)
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id'))
UNION ALL
SELECT p.id_professional, p.name, ui.login
  FROM professional p
  JOIN ab_user_info ui
    ON (ui.id_ab_user_info = p.id_professional)
 WHERE ui.login IS NOT NULL
   AND sys_context('ALERT_CONTEXT', 'i_scenario') = 2
   AND EXISTS
 (SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         INNER JOIN category c
            ON c.id_category = pt.id_category
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND ((pt.flg_group = 'C' AND pt.flg_type = 'N' AND c.flg_type = 'N') OR
               (pt.flg_group = 'P' AND pt.flg_type = 'D' AND c.flg_type = 'D') OR
               (pt.id_profile_template = 22 AND c.flg_type = 'T' AND sys_context('ALERT_CONTEXT', 'l_prof_cat') != 2))
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id'))
UNION ALL
SELECT p.id_professional, p.name, ui.login
  FROM professional p
  JOIN ab_user_info ui
    ON (ui.id_ab_user_info = p.id_professional)
 WHERE ui.login IS NOT NULL
   AND sys_context('ALERT_CONTEXT', 'i_scenario') = 4
   AND EXISTS (SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         INNER JOIN category c
            ON c.id_category = pt.id_category
           AND c.flg_type = 'N'
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.flg_group = 'C'
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id'))
UNION ALL
SELECT p.id_professional, p.name, ui.login
  FROM professional p
  JOIN ab_user_info ui
    ON (ui.id_ab_user_info = p.id_professional)
 WHERE ui.login IS NOT NULL
   AND sys_context('ALERT_CONTEXT', 'i_scenario') = 3
   AND EXISTS (SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         INNER JOIN category c
            ON c.id_category = pt.id_category
           AND c.flg_type = 'N'
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.flg_group = 'C'
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id')
        UNION ALL
        SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         INNER JOIN category c
            ON c.id_category = pt.id_category
           AND c.flg_type = 'D'
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.flg_group = 'P'
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id'))
UNION ALL
SELECT p.id_professional, p.name, ui.login
  FROM professional p
  JOIN ab_user_info ui
    ON (ui.id_ab_user_info = p.id_professional)
 WHERE ui.login IS NOT NULL
   AND sys_context('ALERT_CONTEXT', 'i_tecnician') = 'N'
   AND sys_context('ALERT_CONTEXT', 'i_scenario') = 5
   AND EXISTS (SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         INNER JOIN category c
            ON c.id_category = pt.id_category
           AND c.flg_type = 'N'
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.flg_group = 'C'
           AND pt.flg_type = 'N'
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id')
        UNION ALL
        SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         INNER JOIN category c
            ON c.id_category = pt.id_category
           AND c.flg_type = 'D'
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.flg_group = 'P'
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id'))
UNION ALL
SELECT p.id_professional, p.name, ui.login
  FROM professional p
  JOIN ab_user_info ui
    ON (ui.id_ab_user_info = p.id_professional)
 WHERE ui.login IS NOT NULL
   AND sys_context('ALERT_CONTEXT', 'i_tecnician') = 'Y'
   AND sys_context('ALERT_CONTEXT', 'i_scenario') = 5
   AND EXISTS (SELECT 0
          FROM prof_institution pi
         INNER JOIN prof_profile_template ppt
            ON (ppt.id_professional = pi.id_professional AND ppt.id_institution = pi.id_institution)
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template)
         INNER JOIN category c
            ON c.id_category = pt.id_category
           AND c.flg_type = 'T'
         WHERE pi.id_professional = p.id_professional
           AND pi.id_institution = sys_context('ALERT_CONTEXT', 'i_prof_institution')
           AND pi.dt_end_tstz IS NULL
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.flg_group = 'C'
           AND pt.flg_type = 'T'
           AND pt.id_software = 16
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id'));
