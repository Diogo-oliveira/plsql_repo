create or replace view V_PROC_HAND_OFF_ON_HOLD as
select * from v_proc_hand_off
where flg_status = 'D';

create or replace view V_PROC_HAND_OFF_ON_HOLD as
select * from v_proc_hand_off
where flg_status in ('S', 'D', 'R', 'P', 'V', 'A', 'X');
