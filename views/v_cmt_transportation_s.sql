CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_TRANSPORTATION_S AS
SELECT "DESC_TRANSPORTATION","ID_CNT_TRANSPORTATION","FLG_DOCTOR_ADMIN","FLG_ARRIVAL_DEPARTURE"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_transp_entity)
                  FROM dual) desc_transportation,
               a.id_content id_cnt_transportation,
               a.flg_type flg_doctor_admin,
               a.flg_transp flg_arrival_departure
          FROM transp_entity a
         INNER JOIN TABLE(pk_translation.get_search_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), sys_context('ALERT_CONTEXT', 'SEARCH_TEXT'), 'TRANSP_ENTITY.CODE_TRANSP_ENTITY')) t
            ON t.code_translation = a.code_transp_entity
         WHERE a.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
           AND a.flg_available = 'Y')
 WHERE desc_transportation IS NOT NULL;

