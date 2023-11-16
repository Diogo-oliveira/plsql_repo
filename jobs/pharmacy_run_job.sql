declare 

  new_job binary_integer;

begin

  dbms_job.submit(job => new_job,

                      what => 'DECLARE 

  RetVal BOOLEAN;

BEGIN 

 

  RetVal := ALERT.create_unidose_today;    

END;',

                      next_date => to_date('21-06-2007 17:15:29', 'dd-mm-yyyy hh24:mi:ss'),

                      interval => 'sysdate+0.007');

  commit;

end;

/
