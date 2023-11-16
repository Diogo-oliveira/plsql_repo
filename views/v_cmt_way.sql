CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_WAY AS
SELECT "DESC_WAY", "ID_CNT_WAY", "FLG_WAY_TYPE", "FLG_TYPE"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_way)
                  FROM dual) desc_way,
               a.id_content id_cnt_way,
               a.flg_way_type,
               a.flg_type
          FROM alert.way a
         WHERE a.flg_available = 'Y'
           AND a.id_way > 0)
 WHERE desc_way IS NOT NULL
 ORDER BY 1;

