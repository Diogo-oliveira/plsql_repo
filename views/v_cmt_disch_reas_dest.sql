CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_DISCH_REAS_DEST AS
WITH tmp AS
 (SELECT DISTINCT id_discharge_reason
    FROM profile_disch_reason pdr
    JOIN discharge_flash_files dff
      ON dff.id_discharge_flash_files = pdr.id_discharge_flash_files
     AND dff.flg_type = 'A'
   WHERE pdr.flg_available = 'Y'
     AND pdr.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
     AND EXISTS
   (SELECT DISTINCT 1
            FROM profile_template pt
            JOIN profile_template_market ptm
              ON ptm.id_profile_template = pt.id_profile_template
            JOIN profile_template_category ptc
              ON ptc.id_profile_template = pt.id_profile_template
           WHERE pt.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
             AND ptm.id_market IN (pk_utils.get_institution_market(sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                   sys_context('ALERT_CONTEXT', 'ID_LANGUAGE')),
                                   0)
             AND pt.flg_available = 'Y'
             AND pt.id_profile_template = pdr.id_profile_template))
SELECT "DESC_DISCHARGE_REASON",
       "ID_CNT_DISCHARGE_REASON",
       "DESC_DISCHARGE_DEST",
       "ID_CNT_DISCHARGE_DEST",
       "ID_INSTITUTION_DEST",
       "FLG_DEFAULT",
       "FLG_DIAG",
       "ID_REPORTS",
       "FLG_MCDT",
       "RANK",
       "FLG_AUTO_PRESC_CANCEL",
       "ID_DISCH_REAS_DEST"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      dr.code_discharge_reason)
                  FROM dual) desc_discharge_reason,
               dr.id_content id_cnt_discharge_reason,
               decode(nvl(drd.id_discharge_dest, 0),
                      0,
                      (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                             i.code_institution)
                         FROM dual),
                      (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                             dd.code_discharge_dest)
                         FROM dual)) desc_discharge_dest,
               dd.id_content id_cnt_discharge_dest,
               i.id_institution id_institution_dest,
               drd.flg_default,
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
          LEFT OUTER JOIN institution i
            ON i.id_institution = drd.id_institution
          LEFT OUTER JOIN discharge_dest dd
            ON dd.id_discharge_dest = drd.id_discharge_dest
           AND dd.flg_available = 'Y'
          LEFT OUTER JOIN tmp tmpp
            ON tmpp.id_discharge_reason = drd.id_discharge_reason
         WHERE drd.id_instit_param = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND drd.id_software_param = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND drd.flg_active = 'A'
           AND drd.id_department IS NULL
           AND drd.id_dep_clin_serv IS NULL
           AND tmpp.id_discharge_reason IS NULL)
 WHERE desc_discharge_reason IS NOT NULL
 ORDER BY desc_discharge_reason, desc_discharge_dest;

