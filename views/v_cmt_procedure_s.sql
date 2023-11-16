CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROCEDURE_S AS
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
       "DESC_ALIAS"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), i.code_intervention)
                  FROM dual) AS desc_procedure,
               i.id_content id_cnt_procedure,
               i.gender,
               i.age_min,
               i.age_max,
               NULL AS cpt_code,
               NULL AS flg_mov_pat,
               NULL AS duration,
               NULL AS prev_recovery_time,
               NULL AS ref_form_code,
               NULL AS barcode,
               NULL AS flg_category_type,
               NULL AS mdm_coding,
               NULL AS rank,
               NULL AS flg_execute,
               NULL AS flg_chargeable,
               i.flg_technical,
               (SELECT val
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                      profissional(0,
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_INSTITUTION'),
                                                                                   sys_context('ALERT_CONTEXT',
                                                                                               'ID_SOFTWARE')),
                                                                      'INTERV_PRESC_DET.FLG_PRTY',
                                                                      NULL))
                 WHERE rownum = 1) flg_priority,
               NULL AS desc_alias
          FROM intervention i
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'INTERVENTION.CODE_INTERVENTION')) t
            ON t.code_translation = i.code_intervention
         WHERE i.flg_status = 'A'
           AND i.id_intervention NOT IN
               (SELECT edcs.id_intervention
                  FROM alert.interv_dep_clin_serv edcs
                 WHERE edcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                   AND edcs.flg_type = 'P'
                   AND edcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
           AND i.flg_category_type = 'P')
 WHERE desc_procedure IS NOT NULL;

