CREATE OR REPLACE VIEW v_analysis_harvest AS
SELECT ah.id_analysis_harvest,
       ah.id_analysis_req_det,
       ah.id_harvest,
       ah.id_analysis_req_par,
       ah.id_sample_recipient,
       ah.num_recipient,
       ah.flg_status
  FROM analysis_harvest ah;
