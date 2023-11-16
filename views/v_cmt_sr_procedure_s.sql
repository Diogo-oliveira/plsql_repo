CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SR_PROCEDURE_S AS
SELECT "DESC_SR_PROCEDURE","ID_CNT_SR_PROCEDURE","GENDER","AGE_MIN","AGE_MAX","DURATION","PREV_RECOVERY_TIME","FLG_CODING"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), i.code_intervention)
                  FROM dual) AS desc_sr_procedure,
               i.id_content id_cnt_sr_procedure,
               i.gender,
               i.age_min,
               i.age_max,
               i.duration,
               i.prev_recovery_time,
               NULL AS flg_coding
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
           AND i.flg_category_type = 'SR'
           AND sys_context('ALERT_CONTEXT', 'ID_SOFTWARE') = 2)
 WHERE desc_sr_procedure IS NOT NULL;

