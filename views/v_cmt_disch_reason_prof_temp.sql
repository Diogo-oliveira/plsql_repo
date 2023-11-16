CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DISCH_REASON_PROF_TEMP AS
SELECT desc_discharge_reason,
       id_cnt_discharge_reason,
       desc_profile_template,
       id_profile_template,
       type_of_discharge,
       professionals_accessibility,
       rank,
       flg_default
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      dr.code_discharge_reason)
                  FROM dual) AS desc_discharge_reason,
               dr.id_content AS id_cnt_discharge_reason,
               (SELECT pk_message.get_message(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), pt.code_profile_template)
                  FROM dual) AS desc_profile_template,
               pt.id_profile_template,
               pdr.id_discharge_flash_files AS type_of_discharge,
               pdr.flg_access AS professionals_accessibility,
               pdr.rank,
               decode(pdr.flg_default, 'Y', 'Yes', 'N', 'No', NULL) AS flg_default
          FROM alert.profile_disch_reason pdr
          JOIN alert.discharge_reason dr
            ON dr.id_discharge_reason = pdr.id_discharge_reason
           AND dr.flg_available = 'Y'
          JOIN alert.profile_template pt
            ON pt.id_profile_template = pdr.id_profile_template
           AND pt.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND pt.flg_available = 'Y'
          JOIN alert.profile_template_market ptm
            ON ptm.id_profile_template = pt.id_profile_template
           AND ptm.id_market IN ((SELECT id_market
                                   FROM alert.institution
                                  WHERE id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')),
                                 0)
         WHERE pdr.flg_available = 'Y'
           AND pdr.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
 WHERE desc_discharge_reason IS NOT NULL
   AND desc_profile_template IS NOT NULL
 ORDER BY 1, 3;

