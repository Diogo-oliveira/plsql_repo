CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROCEDURE_CAT AS
SELECT "DESC_PROCEDURE", "ID_CNT_PROCEDURE", "DESC_PROCEDURE_CAT", "ID_CNT_PROCEDURE_CAT", "RANK"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), i.code_intervention)
                  FROM dual) desc_procedure,
               i.id_content id_cnt_procedure,
               (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'),
                                                      ic.code_interv_category)
                  FROM dual) desc_procedure_cat,
               ic.id_content id_cnt_procedure_cat,
               iic.rank
          FROM alert.intervention i
         INNER JOIN alert.interv_dep_clin_serv idcs
            ON idcs.id_intervention = i.id_intervention
           AND idcs.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
           AND idcs.flg_type = 'P'
           AND idcs.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
         INNER JOIN alert.interv_int_cat iic
            ON iic.id_intervention = i.id_intervention
           AND iic.flg_add_remove = 'A'
           AND iic.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
           AND iic.id_software IN (0, sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
         INNER JOIN alert.interv_category ic
            ON ic.id_interv_category = iic.id_interv_category
           AND ic.flg_available = 'Y'
         WHERE i.flg_status = 'A'
           AND i.flg_category_type = 'P')
 WHERE desc_procedure IS NOT NULL
   AND desc_procedure_cat IS NOT NULL;

