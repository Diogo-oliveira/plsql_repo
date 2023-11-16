declare 
   job NUMBER;
begin
  dbms_job.submit(job => job,
                      what => 'PK_RESET.UPDATE_SCHEDULES;',
                      next_date => to_date('27-07-2007 00:05:00', 'dd-mm-yyyy hh24:mi:ss'),
                      interval => 'SYSDATE+1');
  commit;
end;
/