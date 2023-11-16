DECLARE
    CURSOR c_job IS
        SELECT job
          FROM all_jobs
         WHERE log_user = 'ALERT'
           AND lower(what) LIKE '%inactive_triage_ended_episodes%';
BEGIN
    FOR r_job in c_job
    LOOP
        dbms_job.remove(r_job.job);
    END LOOP;
END;
/
