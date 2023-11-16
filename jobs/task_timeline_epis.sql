BEGIN
    pk_frmw_jobs.parameterize_job(i_owner           => 'ALERT',
                                  i_obj_name        => 'TASK_TIMELINE_EPIS',
                                  i_inst_owner      => 0,
                                  i_job_type        => 'PLSQL_BLOCK',
                                  i_job_action      => 'BEGIN PK_EA_LOGIC_TASKTIMELINE.CLEAN_EPIS_TL_TASKS; END;',
                                  i_repeat_interval => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=01; BYSECOND=0;',
                                  i_start_date      => current_timestamp,
                                  i_id_market       => 0,
                                i_flg_available   => 'N',
                                i_responsible_team => 'INP',
                                  i_comment         => 'Function that clean Task Timeline tasks (task_timeline_ea) that are episodes references (Inpatient and Oris) with begin date bigger than today.');
END;
/
