CREATE OR REPLACE VIEW v_wtl_pref_time AS
SELECT id_wtl_pref_time,
       id_waiting_list,
       flg_status,
       flg_value
  FROM wtl_pref_time;
