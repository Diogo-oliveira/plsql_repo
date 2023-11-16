create or replace view v_hhc_visits as
select
  e.id_episode
, ei.id_schedule
, s.dt_begin_tstz
, e.id_prev_episode
, v.id_visit
, v.id_patient
, e.id_epis_type
, e.flg_status epis_flg_State
, so.id_schedule_outp
--, so.flg_state 'R' so_flg_State
, s.flg_status so_flg_State
, d.flg_status dsc_flg_status
, e.flg_status e_flg_status
, e.flg_ehr    e_flg_ehr
, hr.ID_EPIS_HHC_REQ
, hr.id_epis_hhc
, so.flg_state 
from episode e
join epis_info ei on e.id_episode = ei.id_episode
join schedule s on s.id_schedule = ei.id_schedule
join schedule_outp so on so.id_schedule = ei.id_schedule
join visit v on v.id_visit = e.id_visit
join episode ep on ep.id_episode = e.id_prev_episode
join v_epis_hhc_req hr on hr.id_epis_hhc = ep.id_episode
left join discharge d on d.id_episode = e.id_episode
where 0 = 0
and e.id_epis_type = 50
and s.flg_status != 'C'
and e.flg_status != 'C'
and s.flg_status in ( 'A', 'V' )
;
