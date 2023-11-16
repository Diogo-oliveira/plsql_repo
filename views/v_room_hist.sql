-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-06-28
-- CHANGE REASON: [CEMR-1649] API to manage Bed Room Services
CREATE OR REPLACE VIEW v_room_hist AS
SELECT rh.id_room_hist
  FROM room_hist rh;
-- CHANGE END: Amanda Lee
