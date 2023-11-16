CREATE OR REPLACE VIEW V_SR_SURGERY_TIME AS  
SELECT id_sr_surgery_time,
       code_sr_surgery_time,
       id_software,
       id_institution,
       flg_type,
       flg_available,
       rank,
       adw_last_update,
       flg_pat_status,
       flg_val_prev
  FROM sr_surgery_time;