-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 16-03-2010
-- CHANGE REASON: SCH-386
CREATE OR REPLACE VIEW v_room_dep_clin_serv AS 
SELECT id_room_dep_clin_serv,
       id_room,
       id_dep_clin_serv
  FROM room_dep_clin_serv;
-- CHANGE END: Telmo Castro