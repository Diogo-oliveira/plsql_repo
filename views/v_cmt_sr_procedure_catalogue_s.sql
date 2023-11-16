CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SR_PROCEDURE_CATALOGUE_S AS
SELECT "DESC_SR_PROCEDURE","DESC_ALIAS","ID_CNT_SR_PROCEDURE","GENDER","AGE_MIN","AGE_MAX","CPT_CODE","FLG_MOV_PAT","DURATION","PREV_RECOVERY_TIME","REF_FORM_CODE","BARCODE","MDM_CODING","FLG_TECHNICAL","ID_SR_PROCEDURE","CREATE_TIME"
  FROM (SELECT DISTINCT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               code_intervention)
                           FROM dual) AS desc_sr_procedure,
                        (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               code_intervention_alias)
                           FROM dual) AS desc_alias,
                        id_cnt_sr_procedure,
                        gender,
                        age_min,
                        age_max,
                        cpt_code,
                        flg_mov_pat,
                        duration,
                        prev_recovery_time,
                        ref_form_code,
                        barcode,
                        mdm_coding,
                        flg_technical,
                        id_sr_procedure,
                        to_char(create_time, 'DD-MON-YYYY HH24:MI') AS create_time
          FROM (SELECT i.code_intervention,
                       ia.code_intervention_alias,
                       i.id_content               id_cnt_sr_procedure,
                       i.gender,
                       i.age_min,
                       i.age_max,
                       i.cpt_code,
                       i.flg_mov_pat,
                       i.duration,
                       i.prev_recovery_time,
                       i.ref_form_code,
                       i.barcode,
                       i.mdm_coding,
                       i.flg_technical,
                       i.id_intervention          AS id_sr_procedure,
                       i.create_time
                  FROM alert.intervention i
                 INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'INTERVENTION.CODE_INTERVENTION')) t
                    ON t.code_translation = i.code_intervention
                  LEFT JOIN alert.intervention_alias ia
                    ON ia.id_intervention = i.id_intervention
                   AND ia.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ia.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE i.flg_status = 'A'
                   AND i.flg_category_type = 'SR'
                   AND 'all' != lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'))
                   AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'tmp2.') = 0
                   AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cntx.') = 0
                UNION
                SELECT i.code_intervention,
                       ia.code_intervention_alias,
                       i.id_content               id_cnt_sr_procedure,
                       i.gender,
                       i.age_min,
                       i.age_max,
                       i.cpt_code,
                       i.flg_mov_pat,
                       i.duration,
                       i.prev_recovery_time,
                       i.ref_form_code,
                       i.barcode,
                       i.mdm_coding,
                       i.flg_technical,
                       i.id_intervention          AS id_sr_procedure,
                       i.create_time
                  FROM alert.intervention i
                  LEFT JOIN alert.intervention_alias ia
                    ON ia.id_intervention = i.id_intervention
                   AND ia.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ia.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE i.flg_status = 'A'
                   AND i.flg_category_type = 'SR'
                   AND 'all' = lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'))
                UNION
                SELECT i.code_intervention,
                       ia.code_intervention_alias,
                       i.id_content               id_cnt_sr_procedure,
                       i.gender,
                       i.age_min,
                       i.age_max,
                       i.cpt_code,
                       i.flg_mov_pat,
                       i.duration,
                       i.prev_recovery_time,
                       i.ref_form_code,
                       i.barcode,
                       i.mdm_coding,
                       i.flg_technical,
                       i.id_intervention          AS id_sr_procedure,
                       i.create_time
                  FROM alert.intervention i
                  LEFT JOIN alert.intervention_alias ia
                    ON ia.id_intervention = i.id_intervention
                   AND ia.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                   AND ia.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                 WHERE i.flg_status = 'A'
                   AND i.flg_category_type = 'SR'
                   AND i.id_content = sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')))
 WHERE desc_sr_procedure IS NOT NULL
 ORDER BY 1;

