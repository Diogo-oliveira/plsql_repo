CREATE OR REPLACE VIEW v_wtl_ptreason_wtlist AS
SELECT id_wtl_ptreason_wtlist, id_wtl_ptreason, id_waiting_list, flg_status
  FROM wtl_ptreason_wtlist;
