CREATE OR REPLACE VIEW v_wtl_prof AS
SELECT id_wtl_prof, id_prof, id_waiting_list, id_episode, flg_type, flg_status
  FROM wtl_prof;
   
