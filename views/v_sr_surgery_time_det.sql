CREATE OR REPLACE VIEW V_SR_SURGERY_TIME_DET AS   
SELECT id_sr_surgery_time_det,
       id_sr_surgery_time,
       id_episode,
       id_professional,
       flg_status,
       id_prof_cancel,
       adw_last_update,
       dt_surgery_time_det_tstz,
       dt_reg_tstz,
       dt_cancel_tstz,
       ins_order
  FROM sr_surgery_time_det;