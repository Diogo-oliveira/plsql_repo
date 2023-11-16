create or replace view V_LAB_HAND_OFF_TO_BE_DONE as
SELECT * FROM v_lab_hand_off
WHERE flg_status in ('R', 'S') 
OR flg_referral in ('R', 'S');
