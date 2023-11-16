-- Guidelines job (run_batch)
declare 
   job_num number;
begin
  dbms_job.submit(job => job_num,
                  what => 'begin pk_guidelines.run_batch_job(2); end;',
                  next_date => sysdate,
                  interval => 'trunc(SYSDATE+2/24,''HH'')');
end;
/

-- Remove Guidelines' job if it exists
declare
       l_job all_jobs.job%type;
begin

		SELECT job
			INTO l_job
			FROM all_jobs
		 WHERE lower(what) LIKE '%pk_guidelines%';

     dbms_job.remove(l_job);

exception
     when others then
     dbms_output.put_line('Guidelines job does not exist.');
end;
/