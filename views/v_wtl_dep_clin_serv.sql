CREATE OR REPLACE VIEW v_wtl_dep_clin_serv AS
SELECT id_wtl_dcs, id_dep_clin_serv, id_waiting_list, id_episode, flg_type, flg_status
  FROM wtl_dep_clin_serv;
