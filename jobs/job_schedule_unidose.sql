-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 26/11/2012
-- CHANGED REASON: ARCHDB-1284
BEGIN
    dbms_scheduler.drop_job(job_name => 'JOB_SCHEDULE_UNIDOSE');
END;
/
-- CHANGE END: Pedro Teixeira
