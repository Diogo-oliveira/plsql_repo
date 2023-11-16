create or replace view V_PROC_HAND_OFF_IN_PROGRESS as
select * from v_proc_hand_off
where flg_status in ('S', 'P', 'E');
   
create or replace view V_PROC_HAND_OFF_IN_PROGRESS as
select * from v_proc_hand_off
where flg_status in ('E', 'I');
   
