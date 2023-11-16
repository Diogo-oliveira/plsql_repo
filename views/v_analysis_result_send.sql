CREATE OR REPLACE VIEW v_analysis_result_send AS
SELECT ars.id_analysis_result_send,
       ars.id_analysis_req_det,
       ars.id_prof_cc,
       ars.id_prof_bcc,
       ars.email_cc,
       ars.email_bcc,
       ars.flg_status
  FROM analysis_result_send ars;
