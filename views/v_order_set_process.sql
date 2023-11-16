-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 06/03/2012
-- CHANGE REASON: [ALERT-221667]
CREATE OR REPLACE VIEW v_order_set_process
AS
SELECT os.id_order_set AS id_order_set_current,
       (SELECT os2.id_order_set
          FROM alert.order_set os2
         WHERE os2.id_order_set_previous_version IS NULL
         START WITH os2.id_order_set = os.id_order_set
        CONNECT BY os2.id_order_set = PRIOR os2.id_order_set_previous_version) AS id_order_set_original,
       osp.id_order_set_process AS id_order_set_process,
       os.title AS order_set_title,
       osp.id_episode AS id_episode,
       osp.id_patient AS id_patient,
       osp.id_professional AS id_prof_request,
       osp.flg_status AS process_status,
       osp.dt_order_set_process_tstz AS dt_order_set_process_tstz
  FROM alert.order_set os
  JOIN alert.order_set_process osp
    ON os.id_order_set = osp.id_order_set
 WHERE osp.flg_status != 'T';
-- CHANGE END: Tiago Silva