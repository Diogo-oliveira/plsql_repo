create or replace view v_check_exist_rec_temp as
select 'Y' flg_exist,  t.id_episode, t.flg_temp, t.id_professional from 
  		  (select o.id_episode, o.flg_temp, o.id_professional 
	 	  from  epis_observation o 
union 
  		  select e.id_episode, e.flg_temp, e.id_professional 
	 	  from  epis_obs_exam e 
union 
	 	  select a.id_episode, a.flg_temp, a.id_professional 
	 	  from  epis_anamnesis a) t
