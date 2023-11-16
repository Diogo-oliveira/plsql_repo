CREATE OR REPLACE VIEW V_TASK_GROUP AS
SELECT tg.id_task_group, tg.code_task_group, tg.author, tg.dt_group_tstz, tg.flg_status, tg.id_institution, tg.rank
  FROM task_group tg
 WHERE tg.flg_status in ('A', 'I');
