CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_SR_PROCEDURE_AVAILABLE_S AS
WITH tmp AS
 (SELECT /*+ MATERIALIZED */
   *
    FROM (SELECT DISTINCT id_cnt_sr_procedure,
                          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                 a.code_intervention)
                             FROM dual) AS desc_translation,
                          (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                                 ia.code_intervention_alias)
                             FROM dual) AS desc_alias
            FROM (SELECT id_cnt_sr_procedure, code_intervention, id_intervention
                    FROM (SELECT i.id_content id_cnt_sr_procedure, i.code_intervention, i.id_intervention
                            FROM intervention i
                            JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'INTERVENTION.CODE_INTERVENTION')) t
                              ON t.code_translation = i.code_intervention
                           WHERE i.flg_status = 'A'
                             AND i.flg_category_type = 'SR'
                             AND lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')) != 'all'
                             AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'tmp2.') = 0
                             AND instr(lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')), 'cntx.') = 0)
                  UNION
                  SELECT id_cnt_sr_procedure, code_intervention, id_intervention
                    FROM (SELECT i.id_content id_cnt_sr_procedure, i.code_intervention, i.id_intervention
                            FROM intervention i
                           WHERE i.flg_status = 'A'
                             AND i.flg_category_type = 'SR'
                             AND 'all' = lower(sys_context('ALERT_CONTEXT', 'SEARCH_TEXT')))
                  UNION
                  SELECT id_cnt_sr_procedure, code_intervention, id_intervention
                    FROM (SELECT i.id_content id_cnt_sr_procedure, i.code_intervention, i.id_intervention
                            FROM intervention i
                           WHERE i.flg_status = 'A'
                             AND i.flg_category_type = 'SR'
                             AND i.id_content = sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'))
                  MINUS
                  SELECT id_content AS id_cnt_sr_procedure, i.code_intervention, i.id_intervention
                    FROM intervention i
                    JOIN v_cmt_sr_procedure_available avlb
                      ON i.id_content = avlb.id_cnt_sr_procedure) a
            LEFT JOIN intervention_alias ia
              ON ia.id_intervention = a.id_intervention
             AND ia.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
             AND ia.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
   WHERE desc_translation IS NOT NULL)
SELECT desc_sr_procedure,
       desc_alias,
       id_cnt_sr_procedure,
       desc_procedure_cat,
       id_cnt_procedure_cat,
       nvl(rank, 0) rank,
       nvl(flg_execute, 'Y') flg_execute,
       nvl(flg_chargeable, 'N') flg_chargeable,
       nvl(flg_timeout, 'N') flg_timeout,
       flg_priority
  FROM (SELECT DISTINCT tmp.desc_translation AS desc_sr_procedure,
                        tmp.desc_alias AS desc_alias,
                        tmp.id_cnt_sr_procedure,
                        (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                               ic.code_interv_category)
                           FROM dual) AS desc_procedure_cat,
                        ic.id_content id_cnt_procedure_cat,
                        NULL AS rank,
                        NULL AS flg_execute,
                        NULL AS flg_chargeable,
                        NULL AS flg_timeout,
                        NULL AS flg_priority,
                        row_number() over(PARTITION BY i.id_intervention ORDER BY iic.id_interv_category DESC) AS rn
          FROM intervention i
          JOIN tmp tmp
            ON tmp.id_cnt_sr_procedure = i.id_content
          LEFT JOIN interv_int_cat iic
            ON iic.id_intervention = i.id_intervention
           AND iic.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND iic.id_software IN (0, sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
           AND iic.flg_add_remove = 'A'
          LEFT JOIN interv_category ic
            ON iic.id_interv_category = ic.id_interv_category
           AND ic.flg_available = 'Y')
 WHERE rn = 1
 ORDER BY 1;

