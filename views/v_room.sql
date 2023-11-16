-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-06-28
-- CHANGE REASON: [CEMR-1649] API to manage Bed Room Services Dep_clin_serv
CREATE OR REPLACE VIEW V_ROOM AS
SELECT r.id_room,
       r.flg_prof,
       r.id_department,
       r.code_room,
       r.capacity,
       r.interval_time,
       r.flg_recovery,
       r.flg_lab,
       r.flg_wait,
       r.flg_wl,
       r.flg_transp,
       r.code_abbreviation,
       r.id_floors_department,
       r.flg_available,
       r.id_room_type,
       r.flg_schedulable,
       r.desc_room,
       r.desc_room_abbreviation,
	   r.flg_selected_specialties,
	   r.rank
  FROM room r;
-- CHANGE END: Amanda Lee
