CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SR_PROCEDURE AS
SELECT "DESC_SR_PROCEDURE",
       "ID_CNT_SR_PROCEDURE",
       "ICD",
       "GENDER",
       "AGE_MIN",
       "AGE_MAX",
       "DURATION",
       "PREV_RECOVERY_TIME",
       "FLG_CODING",
       "ID_SR_PROCEDURE"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), i.code_intervention)
                  FROM dual) desc_sr_procedure,
               i.id_content id_cnt_sr_procedure,
               i.cpt_code AS icd,
               i.gender,
               i.age_min,
               i.age_max,
               i.duration,
               i.prev_recovery_time,
               NULL AS flg_coding,
               i.id_intervention AS id_sr_procedure
          FROM alert.intervention i
         INNER JOIN alert.interv_dep_clin_serv idcs
            ON idcs.id_intervention = i.id_intervention
         WHERE idcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND idcs.flg_type = 'P'
           AND idcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
           AND i.flg_status = 'A'
           AND i.flg_category_type = 'SR'
           AND sys_context('ALERT_CONTEXT', 'ID_SOFTWARE') = 2)
 WHERE desc_sr_procedure IS NOT NULL;

