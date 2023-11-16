
DECLARE
    PROCEDURE remove_job(l_text IN VARCHAR2) IS
        l_job_id NUMBER(24);
    
        CURSOR c_job IS
            SELECT job
              FROM all_jobs dj
             WHERE dj.log_user = 'ALERT'
               AND upper(dj.what) LIKE '%' || upper(l_text) || '%';
    
    BEGIN
    
        FOR r_job IN c_job
        LOOP
        
            dbms_job.remove(r_job.job);
            COMMIT;
        
        END LOOP;
    
    END remove_job;

BEGIN

    remove_job('PK_DOC.DELETE_DOCS');--

    remove_job('PK_SYSTRACKING.CLEAN_OLD');--

    remove_job('PK_ALERTS.PURGE_ALL_ALERTS');--

    remove_job('PK_DISCHARGE.SET_END_DAY_DISCHARGES');--

    remove_job('PK_ALERTS.UPDATE_ALERTS_GROUP_1');--

    remove_job('PK_ALERTS.UPDATE_ALERTS_GROUP_2');--
    
    remove_job('SELECT 2 INTO X FROM DUAL');-- This one will not be recreated
END;
/

