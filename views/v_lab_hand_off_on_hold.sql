create or replace view V_LAB_HAND_OFF_ON_HOLD as
SELECT * FROM v_lab_hand_off
WHERE flg_status in ('D', 'S') 
AND flg_referral in ('R', 'S');
