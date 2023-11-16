CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SR_PROC_PAST_HISTORY AS
SELECT "DESC_SR_PROCEDURE","ID_CNT_SR_PROCEDURE","STANDARD_CODE","GENDER","AGE_MIN","AGE_MAX","DURATION","PREV_RECOVERY_TIME","FLG_CODING","DESC_FLG_CODING"
  FROM (SELECT DISTINCT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               i.code_intervention)
                           FROM dual) AS desc_sr_procedure,
                        i.id_content id_cnt_sr_procedure,
                        ic.standard_code,
                        i.gender,
                        i.age_min,
                        i.age_max,
                        i.duration,
                        i.prev_recovery_time,
                        sic.flg_coding,
                        pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), c.code_codification) AS desc_flg_coding
          FROM alert.intervention i
          JOIN alert.interv_codification ic
            ON ic.id_intervention = i.id_intervention
          JOIN alert.sr_interv_codification sic
            ON sic.id_codification = ic.id_codification
          JOIN alert.codification c
            ON c.id_codification = ic.id_codification
          JOIN alert.interv_dep_clin_serv idcs
            ON idcs.id_intervention = i.id_intervention
           AND idcs.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
           AND idcs.id_software IN (0, 2)
           AND idcs.flg_type = 'B'
         WHERE (i.flg_type = 'S' OR i.flg_type IS NULL)
           AND i.flg_category_type = 'SR'
           AND i.flg_status = 'A'
           AND ic.flg_available = 'Y'
           AND sic.flg_coding =
               (SELECT pk_sysconfig.get_config('SURGICAL_PROCEDURES_CODING',
                                               profissional(0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'), 2))
                  FROM dual))
 WHERE desc_sr_procedure IS NOT NULL;

