-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 06/12/2011 
-- CHANGE REASON: [ALERT-208518] 

Declare

cursor c_episode
IS
select count(distinct id_sr_epis_interv) nCount, id_episode
from sr_epis_interv sei
group by id_episode;


cursor c_sr_epis_interv 
(v_id_episode sr_epis_interv.id_episode%TYPE)
IS
Select sei.*
From sr_epis_interv sei
Where sei.id_episode = v_id_episode;


cursor c_team 
(v_episode sr_prof_team_det.id_episode%TYPE)
IS
Select sptd.*
From sr_prof_team_det sptd
Where sptd.id_episode = v_episode;


l_time number;
nTeam number;

Begin

  FOR i IN c_episode
  LOOP

      select count(*)
       into nTeam
       From sr_prof_team_det
       where id_episode = i.id_episode
         and id_sr_epis_interv is not null;
  
     If nTeam > 0 Then
    
    l_time := 1;
    For j IN c_sr_epis_interv (i.id_episode) loop

      If l_time = 1 Then
        Update sr_prof_team_det s
          Set s.id_sr_epis_interv = j.id_sr_epis_interv
        Where s.id_episode = i.id_episode
        and s.id_sr_epis_interv is null;
      End if;
     
       If i.nCount > 0 and l_time > 1 Then

         For l IN c_team (i.id_episode) loop
           insert into sr_prof_team_det
           (id_sr_prof_team_det, id_surgery_record, id_episode, id_prof_team_leader, id_professional,  id_category_sub, id_prof_team, flg_status, id_prof_reg, 
           id_prof_cancel, dt_begin_tstz, dt_end_tstz, dt_reg_tstz, dt_cancel_tstz, id_episode_context, id_sr_epis_interv)
           Values 
           (seq_sr_prof_team_det.NEXTVAL, l.id_surgery_record, l.id_episode, l.id_prof_team_leader, l.id_professional, l.id_category_sub, l.id_prof_team, 
            l.flg_status, l.id_prof_reg, l.id_prof_cancel, l.dt_begin_tstz, l.dt_end_tstz, l.dt_reg_tstz, l.dt_cancel_tstz, l.id_episode_context, j.id_sr_epis_interv);
         End loop; -- c_team
        
       End if;

       l_time := l_time + 1;


    End loop; -- c_epis_interv


    commit;

    End if; -- nTeam

  END LOOP; -- c_episode
  
End;
/
