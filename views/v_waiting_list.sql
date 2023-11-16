CREATE OR REPLACE VIEW v_waiting_list AS
SELECT wl.id_waiting_list,
       wl.id_patient,
       wl.id_prof_req,
       wl.dt_placement,
       wl.flg_type,
       wl.flg_status,
       wl.dt_dpb,
       wl.dt_dpa,
       wl.dt_surgery,
       wl.dt_admission,
       wl.min_inform_time,
       wl.id_wtl_urg_level,
       (SELECT ul.id_content FROM wtl_urg_level ul WHERE ul.id_wtl_urg_level = wl.id_wtl_urg_level) urg_level_content,
       wl.id_prof_reg,
       wl.dt_reg,
       wl.id_cancel_reason,
       wl.id_prof_cancel,
       wl.dt_cancel,
       wl.notes_cancel,
       wl.id_external_request,
       wl.func_eval_score,
       wl.notes_edit
  FROM waiting_list wl;
