CREATE OR REPLACE VIEW v_wtl_unav AS
SELECT id_wtl_unav, id_waiting_list, dt_unav_start, dt_unav_end, flg_status
  FROM wtl_unav;
