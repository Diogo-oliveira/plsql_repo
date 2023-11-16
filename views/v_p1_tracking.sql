CREATE OR REPLACE VIEW v_p1_tracking AS
SELECT id_tracking,
       ext_req_status,
       id_external_request,
       id_institution,
       id_professional,
       flg_type,
       id_prof_dest,
       id_dep_clin_serv,
       round_id,
       reason_code,
       flg_reschedule,
       flg_subtype,
       decision_urg_level,
       dt_tracking_tstz,
       id_reason_code,
       id_schedule,
       id_inst_dest
  FROM p1_tracking;
