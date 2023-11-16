BEGIN
    -- Call the procedure
    pk_frmw_jobs.remove_job_configuration(i_owner => 'ALERT', i_obj_name => 'TASK_TIMELINE_CLEAN_EPIS');
END;
