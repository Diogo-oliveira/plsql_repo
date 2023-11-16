CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROFILES AS
SELECT DISTINCT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), s.code_software)
                   FROM dual) AS software_desc,
                pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), pt.code_profile_template) AS profile_desc,
                (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), c.code_category)
                   FROM dual) AS category_desc,
                ptc.id_category,
                pt.id_profile_template AS id_profile
  FROM profile_template pt
  JOIN profile_template_market ptm
    ON ptm.id_profile_template = pt.id_profile_template
  JOIN profile_template_category ptc
    ON ptc.id_profile_template = pt.id_profile_template
  JOIN category c
    ON c.id_category = ptc.id_category
  JOIN software s
    ON s.id_software = pt.id_software
 WHERE pt.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
   AND ptm.id_market IN (pk_utils.get_institution_market(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                         sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')),
                         0)
   AND pt.flg_available = 'Y'
   AND ptc.id_category IN (1, 2)
 ORDER BY 4, 2;

