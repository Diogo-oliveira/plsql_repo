create or replace view V_EXAMS_HAND_OFF_OE_TO_BE_DONE as
select * from v_exams_hand_off
where flg_type != 'I' 
AND flg_status = 'R';
