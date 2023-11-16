CREATE OR REPLACE FUNCTION sr_act_schedule_date RETURN BOOLEAN is
/******************************************************************************
   OBJECTIVO:   Actualiza as datas/horas dos agendamentos do Bloco Operatório com a data/hora do sistema, 
	                  de forma a que possamos ter sempre nas grelhas os agendamentos do dia.
   PARAMETROS:  ENTRADA: 
                       SAIDA:   
  
  CRIAÇÃO: RB 2006/04/10
  NOTAS:     
******************************************************************************/

cursor c1 is
select sr.id_schedule_sr, s.rowid linha_s, sr.rowid linha_sr, r.rowid linha_r, rec.rowid linha_rec,
         sr.dt_target, sr.dt_interv_preview, r.dt_start, sr.id_episode
from schedule s, schedule_sr sr, room_scheduled r,sr_surgery_record rec 
where sr.id_schedule = s.id_schedule
and r.id_schedule(+) = s.id_schedule
and rec.id_schedule_sr(+) = sr.id_schedule_sr
order by sr.id_episode;

cursor c2 is
select rowid linha, chklist_date, chklist_verify_date
from sr_chklist_det
where chklist_date is not null 
or chklist_verify_date is not null;

cursor c3 is
select rowid linha, dt_start, dt_end
from sr_prof_recov_schd;

begin
   for i in c1 loop
	    update schedule_sr
		 set dt_target = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(i.dt_target, 'hh24:mi.ss'), 'yyyymmdd hh24:mi:ss') 
	    where rowid = i.linha_sr;
		 
		 if i.id_schedule_sr != 6 then 
   		 update schedule_sr
   		 set dt_interv_preview = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(i.dt_interv_preview, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss') 
   		 where rowid = i.linha_sr;
		 else
   		 update schedule_sr
   		 set dt_interv_preview = to_date(to_char(trunc(sysdate+1), 'yyyymmdd')||' '||to_char(i.dt_interv_preview, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss') 
   		 where rowid = i.linha_sr;		 
		 end if;
		 
		 if i.dt_start is not null then
		    update room_scheduled
		    set dt_start = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(i.dt_start, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
		    where rowid = i.linha_r; 
		 end if;
             
             --Registo de intervenção
             update sr_surgery_record
             set dt_anest_start = decode(dt_anest_start, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_anest_start, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
             	dt_anest_end = decode(dt_anest_end, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_anest_end, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')) ,
                  dt_sr_entry = decode(dt_sr_entry, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_sr_entry, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
                  dt_sr_exit = decode(dt_sr_exit, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_sr_exit, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
                  dt_room_entry = decode(dt_room_entry, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_room_entry, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
                  dt_room_exit = decode(dt_room_exit, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_room_exit, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
                  dt_rcv_entry = decode(dt_rcv_entry, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_rcv_entry, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
                  dt_rcv_exit = decode(dt_rcv_exit, to_date(null), to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_rcv_exit, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'))
             where rowid = i.linha_rec;    
             
             --ANALYSIS
             update analysis_req
             set dt_req =  to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'),
                  dt_begin = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_begin, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_episode = i.id_episode;
             
             update analysis_req_det
             set dt_target = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_target, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
             	dt_final_target = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_final_target, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
                  dt_final_result = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_final_result, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_analysis_req in (select distinct id_analysis_req from analysis_req where id_episode = i.id_episode);

             --EXAM
		 update exam_req
             set dt_req = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
             	dt_begin = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_begin, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_episode = i.id_episode;
             
             update exam_req_det
             set dt_target = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_target, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
             	dt_final_target = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_final_target, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_exam_req in (select distinct id_exam_req from exam_req where id_episode = i.id_episode);
             
             --INTERVENTION
             update interv_prescription
             set dt_interv_prescription = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_interv_prescription, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
             	dt_begin = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_begin, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_episode = i.id_episode; 
             
             update interv_presc_det
             set dt_begin = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_begin, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_interv_prescription in (select distinct id_interv_prescription from interv_prescription where id_episode = i.id_episode);
             
             --DRUG
             update drug_prescription
             set dt_drug_prescription = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_drug_prescription, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
             	dt_begin = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_begin, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_episode = i.id_episode;
              
             update drug_presc_det
             set dt_begin = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_begin, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_drug_prescription in (select distinct id_drug_prescription from drug_prescription where id_episode = i.id_episode); 
             
--              --HEMO
--              update hemo_req
--              set dt_hemo_req = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_hemo_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
--              	dt_target = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_target, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
--              where id_episode = i.id_episode;
--              
--              --MATERIAL
--              update material_req
--              set dt_req = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
--              	dt_start_req = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_start_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'),
--                   dt_end_req = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_end_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
--              where id_episode = i.id_episode;
             
             update sr_reserv_req
             set dt_req = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
             	dt_exec = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_exec, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
                  dt_cancel = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_cancel, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_episode = i.id_episode;
             
             update sr_posit_req
             set dt_posit_req = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_posit_req, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
             	dt_cancel = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_cancel, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
                  dt_exec = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_exec, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'), 
                  dt_verify = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_verify, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
             where id_episode = i.id_episode;                         
	
	end loop;
	
	for j in c2 loop
		   update sr_chklist_det
		   set chklist_date = decode(j.chklist_date, null, to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(j.chklist_date, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
		        chklist_verify_date = decode(j.chklist_verify_date, null, to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(j.chklist_verify_date, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'))
		   where rowid = j.linha;
	
	end loop;
	
	for x in c3 loop
	        update sr_prof_recov_schd
		     set dt_start = decode(x.dt_start, null, to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(x.dt_start, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')),
		          dt_end = decode(x.dt_end, null, to_date(null), to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(x.dt_end, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss'))
			where rowid = x.linha;    
	
	end loop;
      
      --Actualiza salas
      update sr_room_status
      set dt_status = to_date(to_char(trunc(sysdate), 'yyyymmdd')||' '||to_char(dt_status, 'hh24:mi:ss'), 'yyyymmdd hh24:mi:ss')
      where dt_status is not null;
	
   commit;
	RETURN TRUE;
	
	exception
	WHEN OTHERS then
		  RETURN FALSE;
END Sr_act_schedule_date;
/


-- CHANGED BY: Pedro Santos
-- CHANGE: 2009-APR-3
-- CHANGE REASON: ALERT-22278
DROP FUNCTION sr_act_schedule_date;
-- CHANGE END