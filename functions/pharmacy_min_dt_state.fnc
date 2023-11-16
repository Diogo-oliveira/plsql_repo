
create or replace function pharmacy_min_dt_state (i_st_dt t_rec_pharm_state_dt) return number
aggregate using aggr_pharm_min_dt_state;
/

drop function pharmacy_min_dt_state;

create or replace function pharmacy_min_dt_state (i_st_dt t_rec_pharm_state_dt_rank) return t_rec_pharm_state_dt
aggregate using aggr_pharm_min_dt_state;
/
