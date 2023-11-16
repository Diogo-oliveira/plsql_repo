CREATE OR REPLACE VIEW V_MOVEMENT AS
SELECT id_movement,
       id_episode,
       id_prof_move,
       id_room_from,
       id_room_to,
       id_necessity,
       dt_req_tstz,
       dt_begin_tstz,
       id_prof_request,
       id_prof_receive,
       flg_status,
       id_prof_cancel,
       notes_cancel,
       id_episode_write,
       dt_end_tstz,
       dt_cancel_tstz,
       flg_status_prev,
       flg_mov_type
  FROM movement m;