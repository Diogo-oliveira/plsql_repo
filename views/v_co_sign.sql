CREATE OR REPLACE VIEW v_co_sign AS 
SELECT cs.id_co_sign,
       cs.id_task,
       cs.id_task_group,
       cs.id_task_type,
       cs.id_action,
       cs.id_order_type,
       cs.id_episode,
       cs.id_prof_created,
       cs.id_prof_ordered_by,
       cs.id_prof_co_signed,
       cs.dt_created,
       cs.dt_ordered_by,
       cs.dt_co_signed,
       cs.flg_status,
       cs.co_sign_notes
  FROM co_sign cs;
