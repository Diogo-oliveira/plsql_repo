-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-07-13
-- CHANGE REASON: [CEMR-1829] Missing requirements for InterAlert development
CREATE OR REPLACE VIEW v_floors_institution AS
select fi.id_floors_institution,
       fi.id_floors,
       fi.id_institution,
       fi.flg_available,
       fi.id_building
  from floors_institution fi;
-- CHANGE END: Amanda Lee
