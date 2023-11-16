-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-07-13
-- CHANGE REASON: [CEMR-1829] Missing requirements for InterAlert development
CREATE OR REPLACE VIEW v_bed_dep_clin_serv AS
SELECT bdcs.id_bed,
bdcs.id_dep_clin_serv,
bdcs.flg_available
  FROM bed_dep_clin_serv bdcs;
-- CHANGE END: Amanda Lee
