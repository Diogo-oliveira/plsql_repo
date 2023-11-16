create or replace view V_EXAMS_HAND_OFF_IE_IN_PROG as
select * from v_exams_hand_off
where flg_type = 'I'
and flg_status = 'E';
