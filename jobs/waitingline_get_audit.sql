DECLARE
    l_jobid table_number;
BEGIN
    SELECT job BULK COLLECT
      INTO l_jobid
      FROM dba_jobs dj
     WHERE lower(what) LIKE '%pk_waitinglinesonho.getaudit%';

    FOR i IN 1 .. l_jobid.count
    LOOP
        dbms_job.remove(l_jobid(i));
        COMMIT;
    END LOOP;

END;
/

BEGIN
    pk_frmw_jobs.parameterize_job(i_owner             => 'ALERT',
                                  i_obj_name          => 'WAITINGLINE_GET_AUDIT',
                                  i_inst_owner        => 0,
                                  i_job_type          => 'PLSQL_BLOCK',
                                  i_job_action        => 'declare
	x varchar2(1000);
begin
	 x:=pk_waitinglinesonho30/1440.getaudit();
end;',
                                  i_repeat_interval   => 'FREQ=MINUTELY; INTERVAL=2;', --SYSDATE+30/1440 e sysdate + (2/1440)
                                  i_start_date        => current_timestamp,
                                  i_id_market         => 0,
                                  i_flg_available     => 'N',
                                  i_responsible_team  => 'OPR',
                                  i_comment           => 'waitinglinesonho.getaudit',
                                  i_create_immediatly => 'Y');
END;
/
