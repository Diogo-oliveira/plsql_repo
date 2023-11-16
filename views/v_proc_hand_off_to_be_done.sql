create or replace view V_PROC_HAND_OFF_TO_BE_DONE as
select * from v_proc_hand_off
where flg_status in ('R', 'A');
   
create or replace view V_PROC_HAND_OFF_TO_BE_DONE as
select * from v_proc_hand_off
where flg_status in ('S', 'D', 'R', 'P', 'V', 'A', 'X');
   
