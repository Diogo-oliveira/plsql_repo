create or replace view V_EXAMS_HAND_OFF_IE_ON_HOLD as
select * from v_exams_hand_off
WHERE flg_type = 'I'
AND flg_status IN ('D', 'PA', 'A');
