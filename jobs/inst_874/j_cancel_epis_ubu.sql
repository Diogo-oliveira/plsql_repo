BEGIN
     dbms_scheduler.create_job(job_name   => 'J_CANCEL_EPIS_UBU',
                                  job_type   => 'PLSQL_BLOCK',
                                  job_action => 'BEGIN PK_UBU.CANCEL_EPIS_UBU; END;',
                                  start_date => SYSDATE,
																	repeat_interval => 'FREQ=MINUTELY;INTERVAL=60',
																	enabled => TRUE);
		COMMIT;
END;																	
/

