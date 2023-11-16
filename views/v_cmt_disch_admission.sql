CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DISCH_ADMISSION AS
SELECT "DESC_DISCHARGE_REASON",
       "ID_CNT_DISCHARGE_REASON",
       "DESC_ADMISSION_DEST",
       "ID_DEP_CLIN_SERV",
       "ID_DEPARTMENT",
       "FLG_DEFAULT",
       "ID_EPIS_TYPE",
       "TYPE_SCREEN",
       "FLG_DIAG",
       "ID_REPORTS",
       "FLG_MCDT",
       "RANK",
       "FLG_AUTO_PRESC_CANCEL",
       "ID_DISCH_REAS_DEST"
  FROM (SELECT DISTINCT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               dr.code_discharge_reason)
                           FROM dual) desc_discharge_reason,
                        dr.id_content id_cnt_discharge_reason,
                        decode(nvl(drd.id_dep_clin_serv, 0),
                               0,
                               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      dpt.code_department)
                                  FROM dual) || ' - ' || '(SERVICE)',
                               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      dptt.code_department)
                                  FROM dual) || ' - ' ||
                               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      cs.code_clinical_service)
                                  FROM dual) || ' - ' || '(SPECIALITY)') AS desc_admission_dest,
                        drd.id_dep_clin_serv,
                        dpt.id_department,
                        drd.flg_default,
                        drd.id_epis_type,
                        drd.type_screen,
                        drd.flg_diag,
                        drd.id_reports,
                        drd.flg_mcdt,
                        drd.rank,
                        drd.flg_auto_presc_cancel,
                        drd.id_disch_reas_dest
          FROM disch_reas_dest drd
          JOIN discharge_reason dr
            ON drd.id_discharge_reason = dr.id_discharge_reason
           AND dr.flg_available = 'Y'
          JOIN profile_disch_reason pdr
            ON pdr.id_discharge_reason = drd.id_discharge_reason
           AND pdr.flg_available = 'Y'
           AND pdr.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
          JOIN discharge_flash_files dff
            ON dff.id_discharge_flash_files = pdr.id_discharge_flash_files
           AND dff.flg_type = 'A'
          LEFT OUTER JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
           AND dcs.flg_available = 'Y'
          LEFT OUTER JOIN department dptt
            ON dcs.id_department = dptt.id_department
           AND dptt.flg_available = 'Y'
          LEFT OUTER JOIN department dpt
            ON drd.id_department = dpt.id_department
           AND dpt.flg_available = 'Y'
          LEFT OUTER JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
           AND cs.flg_available = 'Y'
         WHERE drd.id_instit_param = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND drd.id_software_param = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND drd.flg_active = 'A'
           AND drd.id_institution IS NULL)
 WHERE desc_discharge_reason IS NOT NULL
 ORDER BY desc_discharge_reason, desc_admission_dest;

