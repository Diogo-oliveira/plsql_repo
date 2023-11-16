-- Sofia Mendes 21-10-2009 ALERT-47804

BEGIN
    DBMS_SCHEDULER.drop_job(job_name => 'BED_MANAGEMENT_JOB1');
END;
/