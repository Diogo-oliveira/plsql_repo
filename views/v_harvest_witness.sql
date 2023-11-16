CREATE OR REPLACE VIEW V_HARVEST_WITNESS AS
SELECT p.id_professional, p.name
  FROM professional p
  JOIN ab_user_info ui
    ON (ui.id_ab_user_info = p.id_professional)
 WHERE ui.login IS NOT NULL
   AND EXISTS (SELECT 0
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
					 AND c.flg_type in ('N','D','T')
           AND pi.flg_state = 'A'
           AND pi.flg_external = 'N'
           AND pt.flg_group IN ('C')
           AND pt.flg_type in ('N','D','T')
           AND pi.id_professional <> sys_context('ALERT_CONTEXT', 'i_prof_id'));