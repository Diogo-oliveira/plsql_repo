CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_CURRENT_SOFT_INST AS
SELECT sys_context('ALERT_CONTEXT', 'ID_INSTITUTION') AS id_institution,
       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), code_institution)
          FROM alert.institution
         WHERE id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')) AS desc_institution,
       sys_context('ALERT_CONTEXT', 'ID_SOFTWARE') AS software,
       (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), code_software)
          FROM alert.software
         WHERE id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')) AS desc_software
  FROM dual;

