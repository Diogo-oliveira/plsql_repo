CREATE OR REPLACE VIEW V_CO_SIGN_HIST AS 
SELECT ch.id_co_sign_hist,
       id_co_sign,
       ch.id_task,
       ch.id_task_group,
       ch.id_task_type,
       ch.id_action,
       ch.id_order_type,
       ch.id_episode,
       ch.id_prof_created,
       ch.id_prof_ordered_by,
       ch.id_prof_co_signed,
       ch.dt_created,
       ch.dt_ordered_by,
       ch.dt_co_signed,
       ch.flg_status,
       ch.co_sign_notes
  FROM co_sign_hist ch;

