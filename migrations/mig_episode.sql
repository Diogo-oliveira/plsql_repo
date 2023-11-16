-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 30/03/2012 15:50
-- CHANGE REASON: [ALERT-225747] 
declare 
l_id_episode table_number:=table_number();
begin
  
  SELECT distinct(e.id_episode) bulk collect
  into l_id_episode
  FROM rehab_epis_encounter ree
  join episode e on e.id_episode=ree.id_episode_rehab
 WHERE ree.flg_status = 'O'
 and e.flg_status!='I';
 
 for i in 1.. l_id_episode.count 
   loop
     dbms_output.put_line('id= '||l_id_episode(i)||' i= '||i);
     
     update episode e 
     set e.flg_status='I'
     where e.id_episode=l_id_episode(i);
   end loop;
 commit; 
end;
/
-- CHANGE END:  Nuno Neves