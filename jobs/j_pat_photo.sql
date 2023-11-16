DECLARE
    CURSOR c_job IS
        SELECT job
          FROM all_jobs
         WHERE log_user = 'ALERT'
           AND lower(what) LIKE '%pk_patphoto.photo_transfer%';
BEGIN
    FOR r_job IN c_job
    LOOP
        dbms_job.remove(r_job.job);
    END LOOP;
END;
/