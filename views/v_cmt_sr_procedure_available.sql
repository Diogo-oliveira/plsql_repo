CREATE OR REPLACE VIEW V_CMT_SR_PROCEDURE_AVAILABLE AS
SELECT DISTINCT desc_sr_procedure,
                desc_alias,
                id_cnt_sr_procedure,
                id_sr_procedure,
                desc_procedure_cat,
                id_cnt_procedure_cat,
                rank,
                flg_execute,
                flg_chargeable,
                flg_timeout,
                flg_priority
  FROM (SELECT t.desc_translation AS desc_sr_procedure,
               i.id_content id_cnt_sr_procedure,
               i.id_intervention AS id_sr_procedure,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      ic.code_interv_category)
                  FROM dual) AS desc_procedure_cat,
               ic.id_content id_cnt_procedure_cat,
               idcs.rank,
               idcs.flg_execute,
               idcs.flg_chargeable,
               idcs.flg_timeout,
               idcs.flg_priority,
               ttt.desc_translation AS desc_alias,
               row_number() over(PARTITION BY i.id_intervention ORDER BY iic.id_interv_category DESC, ia.id_software DESC) AS rn
          FROM intervention i
          JOIN v_cmt_translation_procedure t
            ON t.code_translation = i.code_intervention
          JOIN interv_dep_clin_serv idcs
            ON idcs.id_intervention = i.id_intervention
           AND idcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND idcs.flg_type = 'P'
           AND idcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
          LEFT JOIN interv_int_cat iic
            ON iic.id_intervention = i.id_intervention
           AND iic.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND iic.id_software IN (0, sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
           AND iic.flg_add_remove = 'A'
           AND EXISTS (SELECT 1
                  FROM interv_category id
                 WHERE id.flg_available = 'Y'
                   AND iic.id_interv_category = id.id_interv_category)
          LEFT JOIN interv_category ic
            ON iic.id_interv_category = ic.id_interv_category
          LEFT JOIN intervention_alias ia
            ON ia.id_intervention = i.id_intervention
           AND ia.id_software IN (sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'), 0)
           AND ia.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
          LEFT JOIN v_cmt_translation_proced_alias ttt
            ON ttt.code_translation = ia.code_intervention_alias
         WHERE i.flg_status = 'A'
           AND i.flg_category_type = 'SR')
 WHERE rn = 1
   AND desc_sr_procedure IS NOT NULL
 ORDER BY 1;
