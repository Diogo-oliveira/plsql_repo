CREATE OR REPLACE VIEW v_p1_task_done AS
SELECT id_task_done,
       id_prof_exec,
       id_task,
       id_external_request,
       flg_task_done,
       flg_type,
       notes,
       dt_completed_tstz,
       dt_inserted_tstz,
       flg_status,
       id_group,
       id_inst_exec,
       id_professional,
       id_institution
  FROM p1_task_done;