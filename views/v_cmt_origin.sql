CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_ORIGIN AS
SELECT "DESC_ORIGIN", "ID_CNT_ORIGIN", "ID_ORIGIN", "RANK"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_origin)
                  FROM dual) desc_origin,
               a.id_content id_cnt_origin,
               a.id_origin,
               a.rank
          FROM origin a
         WHERE a.flg_available = 'Y'
           AND a.id_origin IN (SELECT b.id_origin
                                 FROM origin_soft_inst b
                                WHERE b.id_institution = sys_context('ALERT_CONTEXT', 'ID_INSTITUTION')
                                  AND b.id_software = sys_context('ALERT_CONTEXT', 'ID_SOFTWARE')
                                  AND b.flg_available = 'Y'))
 WHERE desc_origin IS NOT NULL;

