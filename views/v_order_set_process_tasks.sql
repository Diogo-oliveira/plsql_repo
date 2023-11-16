-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 06/03/2012
-- CHANGE REASON: [ALERT-221667]
CREATE OR REPLACE VIEW v_order_set_process_tasks
AS
SELECT os.id_order_set AS id_order_set_current,
       (SELECT os2.id_order_set
          FROM alert.order_set os2
         WHERE os2.id_order_set_previous_version IS NULL
         START WITH os2.id_order_set = os.id_order_set
        CONNECT BY os2.id_order_set = PRIOR os2.id_order_set_previous_version) AS id_order_set_original,
       osp.id_order_set_process AS id_order_set_process,
       ospt.id_order_set_process_task AS id_order_set_process_task,
       os.title AS order_set_title,
       osp.id_episode AS id_episode,
       osp.id_patient AS id_patient,
       ospt.id_professional AS id_prof_request,
       ospt.id_task_type AS id_task_type,
       ospt.id_request AS id_request,
       osp.flg_status AS process_status,
       ospt.flg_status AS process_task_status,
       ospt.dt_request_tstz AS dt_task_request_tstz,
       osp.dt_order_set_process_tstz AS dt_order_set_process_tstz
  FROM alert.order_set os
  JOIN alert.order_set_process osp
    ON os.id_order_set = osp.id_order_set
  JOIN alert.order_set_process_task ospt
    ON ospt.id_order_set_process = osp.id_order_set_process
 WHERE osp.flg_status != 'T'
   AND ospt.flg_status != 'T'
   AND ospt.id_request IS NOT NULL;
-- CHANGE END: Tiago Silva