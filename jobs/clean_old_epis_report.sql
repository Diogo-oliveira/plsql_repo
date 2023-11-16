DECLARE
BEGIN
    FOR r_job IN (SELECT *
                    FROM user_jobs
                   WHERE what like '%CLEAN_OLD_EPIS_REPORT%')
    LOOP
       dbms_job.remove(r_job.job);
    END LOOP;
END;
/

BEGIN
    -- Call the procedure
    alert_core_tech.pk_frmw_jobs.parameterize_job(i_owner            => 'ALERT',
                                                  i_obj_name         => 'CLEAN_OLD_EPIS_REPORT_JOB',
                                                  i_inst_owner       => 0,
                                                  i_job_type         => 'STORED_PROCEDURE',
                                                  i_job_action       => 'CLEAN_OLD_EPIS_REPORT',
                                                  i_repeat_interval  => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=01; BYSECOND=0;',
                                                  i_start_date       => current_timestamp,
                                                  i_id_market        => 0,
                                                  i_responsible_team => 'REPORTS',
                                                  i_comment          => 'This is the JOB cleans from epis_report table the reports not printed',
                                                  i_flg_available     => 'Y',
                                                  i_create_immediatly => 'Y');
END;
/

