CREATE OR REPLACE VIEW v_p1_task AS
SELECT id_task,
       code_task,
       desc_task,
       rank,
       flg_type,
       flg_purpose
  FROM p1_task;
