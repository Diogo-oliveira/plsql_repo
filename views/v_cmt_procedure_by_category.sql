CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_PROCEDURE_BY_CATEGORY AS
WITH temp AS
 (SELECT /*+ MATERIALIZED */
  DISTINCT id_cnt_procedure, desc_procedure, id_procedure AS id_intervention
    FROM v_cmt_procedure_available)
SELECT "DESC_PROCEDURE", "ID_CNT_PROCEDURE", "DESC_PROCEDURE_CAT", "ID_CNT_PROCEDURE_CAT", "RANK"
  FROM (SELECT DISTINCT tmp.desc_procedure,
                        tmp.id_cnt_procedure,
                        tt.desc_translation   desc_procedure_cat,
                        ic.id_content        id_cnt_procedure_cat,
                        iic.rank
          FROM intervention i
          JOIN temp tmp
            ON i.id_intervention = tmp.id_intervention
          JOIN interv_int_cat iic
            ON iic.id_intervention = i.id_intervention
           AND iic.flg_add_remove = 'A'
           AND iic.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
           AND iic.id_software IN (0, sys_context('ALERT_CONTEXT', 'ID_SOFTWARE'))
          JOIN interv_category ic
            ON ic.id_interv_category = iic.id_interv_category
           AND ic.flg_available = 'Y'
          JOIN v_cmt_translation_interv_cat tt
            ON tt.code_translation = ic.code_interv_category)
 WHERE desc_procedure IS NOT NULL
   AND desc_procedure_cat IS NOT NULL;

