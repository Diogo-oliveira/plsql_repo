-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-07-13
-- CHANGE REASON: [CEMR-1829] Missing requirements for InterAlert development
CREATE OR REPLACE VIEW v_floors_department AS
SELECT fd.id_floors_department,
fd.id_department,
fd.id_floors_institution
  FROM floors_department fd;
-- CHANGE END: Amanda Lee
