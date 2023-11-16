
create or replace type T_REC_PHARM_PEND as object 
(
  id_patient number(24),
  id_episode number(24),
  flg_type varchar2(1),
  id_state number(4),
  dt_req timestamp(6) with local time zone
);
/
