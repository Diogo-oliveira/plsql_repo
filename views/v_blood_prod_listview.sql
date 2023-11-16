CREATE OR REPLACE VIEW V_BLOOD_PROD_LISTVIEW AS
SELECT ID_BLOOD_PRODUCT_REQ,
       ID_BLOOD_PRODUCT_DET,
       ID_HEMO_TYPE,
       FLG_STATUS_DET,
       FLG_STATUS_REQ,
       FLG_NOTES,
       NOTES,
       NOTES_CANCEL,
       FLG_DOC,
       FLG_REQ_ORIGIN_MODULE,
       STATUS_STR_REQ,
       STATUS_MSG_REQ,
       STATUS_ICON_REQ,
       STATUS_FLG_REQ,
       STATUS_STR,
       STATUS_MSG,
       STATUS_ICON,
       STATUS_FLG,
       FLG_PRIORITY,
       ID_ORDER_RECURRENCE,
       ID_EPISODE,
       FLG_TIME,
       ID_EPISODE_ORIGIN,
       ID_EPIS_TYPE,
       ID_VISIT,
       ID_PATIENT,
       DT_BEGIN_REQ,
       DT_BLOOD_PRODUCT,
       CODE_HEMO_TYPE,
       NOTES_TECH,
       RANK,
       BARCODE_LAB,
       ADVERSE_REACTION,
       QTY_EXEC,
       QTY_RECEIVED,
       QTY_DET,
       DT_BEGIN_DET,
       ADVERSE_REACTION_REQ,
       RANK_REQ,
       sys_context('ALERT_CONTEXT', 'l_limit') as limit
  FROM (SELECT id_blood_product_req,
               id_blood_product_det,
               id_hemo_type,
               flg_status_det,
               flg_status_req,
               flg_notes,
               notes,
               notes_cancel,
               flg_doc,
               flg_req_origin_module,
               status_str_req,
               status_msg_req,
               status_icon_req,
               status_flg_req,
               status_str,
               status_msg,
               status_icon,
               status_flg,
               flg_priority,
               id_order_recurrence,
               id_episode,
               flg_time,
               id_episode_origin,
               id_epis_type,
               id_visit,
               id_patient,
               dt_begin_req,
               dt_blood_product,
               code_hemo_type,
               notes_tech,
               CASE
                    WHEN flg_status_det IS NOT NULL THEN
                     decode(flg_status_det,
                            'R',
                            row_number() over(ORDER BY rank_det, dt_begin_req),
                            row_number() over(ORDER BY rank_req, dt_begin_req DESC))
                    ELSE
                     row_number() over(ORDER BY rank_req ASC, dt_begin_req DESC)
                END rank,
               barcode_lab,
               adverse_reaction,
               qty_exec,
               qty_received,
               coalesce(qty_received, qty_exec) qty_det,
               dt_begin_det,
               adverse_reaction_req,
               rank_req
          FROM (SELECT bpea.id_blood_product_req,
                       bpea.id_blood_product_det,
                       bpea.id_hemo_type,
                       bpea.flg_status_det,
                       bpea.flg_status_req,
                       bpea.flg_notes,
                       bpea.notes,
                       bpea.notes_cancel,
                       bpea.flg_doc,
                       bpea.flg_req_origin_module,
                       bpea.status_str_req,
                       bpea.status_msg_req,
                       bpea.status_icon_req,
                       bpea.status_flg_req,
                       bpea.status_str,
                       bpea.status_msg,
                       bpea.status_icon,
                       bpea.status_flg,
                       bpea.flg_priority,
                       bpea.id_order_recurrence,
                       e.id_episode,
                       bpea.flg_time,
                       bpea.id_episode_origin,
                       e.id_epis_type,
                       e.id_visit,
                       bpea.id_patient,
                       bpea.dt_begin_req,
                       bpea.dt_blood_product,
                       ht.code_hemo_type,
                       bpea.notes_tech,
                       (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                     'BLOOD_PRODUCT_DET.FLG_STATUS',
                                                     bpea.flg_status_det)
                          FROM dual) rank_det,
                       (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                     'BLOOD_PRODUCT_REQ.FLG_STATUS',
                                                     bpea.flg_status_req)
                          FROM dual) rank_req,
                       bpea.barcode_lab,
                       bpea.adverse_reaction,
                       bpea.qty_exec,
                       bpea.qty_received,
                       bpea.dt_begin_det,
                       bpea.adverse_reaction_req
                  FROM blood_products_ea bpea
                  JOIN hemo_type ht
                    ON ht.id_hemo_type = bpea.id_hemo_type
                  JOIN episode e
                    ON e.id_episode = bpea.id_episode
                 WHERE sys_context('ALERT_CONTEXT', 'i_patient') = e.id_patient
                   AND sys_context('ALERT_CONTEXT', 'i_bp_req') = 'Y'
                UNION ALL
                SELECT DISTINCT bpea.id_blood_product_req,
                                NULL id_blood_product_det,
                                NULL id_hemo_type,
                                NULL flg_status_det,
                                bpea.flg_status_req,
                                NULL flg_notes,
                                NULL notes,
                                NULL notes_cancel,
                                NULL flg_doc,
                                bpea.flg_req_origin_module,
                                bpea.status_str_req,
                                bpea.status_msg_req,
                                bpea.status_icon_req,
                                bpea.status_flg_req,
                                NULL status_str,
                                NULL status_msg,
                                NULL status_icon,
                                NULL status_flg,
                                bpea.flg_priority,
                                NULL id_order_recurrence,
                                e.id_episode,
                                bpea.flg_time,
                                bpea.id_episode_origin,
                                e.id_epis_type,
                                e.id_visit,
                                bpea.id_patient,
                                bpea.dt_begin_req,
                                bpea.dt_blood_product,
                                NULL code_hemo_type,
                                NULL notes_tech,
                                NULL rank_det,
                                (SELECT pk_sysdomain.get_rank(sys_context('ALERT_CONTEXT', 'i_lang'),
                                                              'BLOOD_PRODUCT_REQ.FLG_STATUS',
                                                              bpea.flg_status_req)
                                   FROM dual) rank_req,
                                NULL barcode_lab,
                                NULL adverse_reaction,
                                NULL qty_exec,
                                NULL qty_received,
                                bpea.dt_begin_req dt_begin_det,
                                bpea.adverse_reaction_req
                  FROM blood_products_ea bpea
                  JOIN episode e
                    ON e.id_episode = bpea.id_episode
                 WHERE sys_context('ALERT_CONTEXT', 'i_patient') = e.id_patient
                   AND sys_context('ALERT_CONTEXT', 'i_bp_req') = 'N'));