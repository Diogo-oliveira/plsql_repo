CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_ORIGIN_CATALOGUE AS
SELECT desc_origin, id_cnt_origin, rank, id_origin
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_origin)
                  FROM dual) desc_origin,
               a.id_content id_cnt_origin,
               a.rank,
               a.id_origin
          FROM alert_adtcod_cfg.origin a
         WHERE a.flg_available = 'Y')
 WHERE desc_origin IS NOT NULL;

