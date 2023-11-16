CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROCEDURE AS
SELECT "DESC_PROCEDURE",
       "ID_CNT_PROCEDURE",
       "GENDER",
       "AGE_MIN",
       "AGE_MAX",
       "CPT_CODE",
       "FLG_MOV_PAT",
       "DURATION",
       "PREV_RECOVERY_TIME",
       "REF_FORM_CODE",
       "BARCODE",
       "FLG_CATEGORY_TYPE",
       "MDM_CODING",
       "RANK",
       "FLG_EXECUTE",
       "FLG_CHARGEABLE",
       "FLG_TECHNICAL",
       "FLG_PRIORITY",
       "DESC_ALIAS",
       "ID_PROCEDURE"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), i.code_intervention)
                  FROM dual) desc_procedure,
               i.id_content id_cnt_procedure,
               i.gender,
               i.age_min,
               i.age_max,
               i.cpt_code,
               i.flg_mov_pat,
               i.duration,
               i.prev_recovery_time,
               i.ref_form_code,
               i.barcode,
               i.flg_category_type,
               i.mdm_coding,
               idcs.rank,
               idcs.flg_execute,
               idcs.flg_chargeable,
               i.flg_technical,
               (SELECT pk_procedures_utils.get_alias_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                 profissional((SELECT id_professional
                                                                                FROM (SELECT id_professional, rownum rn
                                                                                        FROM (SELECT id_professional
                                                                                                FROM alert.prof_cat pc
                                                                                               WHERE pc.id_institution =
                                                                                                     sys_context('ALERT_CONTEXT',
                                                                                                                 'ID_INSTITUTION')
                                                                                                 AND pc.id_category = 1))
                                                                               WHERE rn = 1),
                                                                              sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'),
                                                                              sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')),
                                                                 i.code_intervention,
                                                                 NULL)
                  FROM dual) desc_alias,
               i.id_intervention AS "ID_PROCEDURE",
               (SELECT nvl(idcs.flg_priority,
                           (SELECT val
                              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(sys_context('ALERT_CONTEXT',
                                                                                              'ID_LANGUAGE'),
                                                                                  profissional(0,
                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                           'ID_INSTITUTION'),
                                                                                               sys_context('ALERT_CONTEXT',
                                                                                                           'ID_SOFTWARE')),
                                                                                  'INTERV_PRESC_DET.FLG_PRTY',
                                                                                  NULL))
                             WHERE rownum = 1))
                  FROM dual) flg_priority
          FROM alert.intervention i
         INNER JOIN alert.interv_dep_clin_serv idcs
            ON idcs.id_intervention = i.id_intervention
         WHERE idcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND idcs.flg_type = 'P'
           AND idcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND i.flg_status = 'A'
           AND i.flg_category_type = 'P')
 WHERE desc_procedure IS NOT NULL;

