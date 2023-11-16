CREATE OR REPLACE FORCE VIEW ALERT.V_CMT_TRANSPORTATION AS
SELECT "DESC_TRANSPORTATION","ID_CNT_TRANSPORTATION","FLG_DOCTOR_ADMIN","FLG_ARRIVAL_DEPARTURE","FLG_DISCHARGE_TRANSFER"
  FROM (SELECT (SELECT pk_translation.get_translation(sys_context('ALERT_CONTEXT', 'ID_LANGUAGE'), a.code_transp_entity)
                  FROM dual) desc_transportation,
               a.id_content id_cnt_transportation,
               a.flg_type flg_doctor_admin,
               a.flg_transp flg_arrival_departure,
               b.flg_type flg_discharge_transfer
          FROM transp_entity a
         INNER JOIN transp_ent_inst b
            ON b.id_transp_entity = a.id_transp_entity
         WHERE b.id_institution IN (sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'), 0)
           AND a.id_institution IN (0, sys_context('ALERT_CONTEXT', 'ID_INSTITUTION'))
           AND a.flg_available = 'Y'
           AND b.flg_available = 'Y')
 WHERE desc_transportation IS NOT NULL;

