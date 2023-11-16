create or replace view V_LAB_HAND_OFF_IN_PROGRESS as
SELECT * FROM v_lab_hand_off
WHERE flg_status in ('E');
