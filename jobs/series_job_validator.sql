DECLARE
    e_existing_job exception;
    PRAGMA EXCEPTION_INIT(e_existing_job, -27477); -- when ORA-27477: "ALERT.CPOE_EXPIRE_JOB" already exists

BEGIN
    dbms_scheduler.create_job(job_name        => 'SERIES_SISPRENATAL',
                              job_type        => 'PLSQL_BLOCK',
                              job_action      => 'BEGIN PK_BACKOFFICE.SERIES_JOB_VALIDATOR; END;',
                              start_date      => trunc(systimestamp),
                              repeat_interval => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0;',
                              enabled         => TRUE,
                              comments        => 'Job that validates the existence of in progress series and changes its state on the end of year');
EXCEPTION
    WHEN e_existing_job THEN
        NULL;                 
END;
/
BEGIN
    -- Call the procedure
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'SERIES_SISPRENATAL',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'PLSQL_BLOCK',
                                  i_job_action        => 'BEGIN PK_BACKOFFICE.SERIES_JOB_VALIDATOR; END;',
                                  i_repeat_interval   => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0;',
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0, 
                                  i_comment           => 'Job that validates the existence of in progress series and changes its state on the end of year',  
                                  i_responsible_team  => 'TOOLS',
                                  i_create_immediatly => 'Y');
END;
/