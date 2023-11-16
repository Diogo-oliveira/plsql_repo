
-- CHANGED BY: Carlos Loureiro
-- CHANGE DATE: 20-SEP-2012 10:00
-- CHANGE REASON: [ARCHDB-1212] CPOE expire job
BEGIN
    -- Call the procedure
    pk_frmw_jobs.parameterize_job(i_owner            => 'ALERT',
                                  i_obj_name         => 'CPOE_EXPIRE_JOB',
                                  i_inst_owner       => 0,
                                  i_job_type         => 'PLSQL_BLOCK',
                                  i_job_action       => 'BEGIN PK_CPOE.CPOE_JOB_EXPIRE; END;',
                                  i_repeat_interval  => 'FREQ = MINUTELY; INTERVAL = 30',
                                  i_start_date      => current_timestamp,
                                  i_id_market        => 0,
                                  i_responsible_team => 'ORDER TOOLS',
                                  i_comment          => 'This job performs CPOE specific tasks (expire processes and tasks)');
END;
/
-- CHANGE END: Carlos Loureiro
