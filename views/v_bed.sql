-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-07-13
-- CHANGE REASON: [CEMR-1829] Missing requirements for InterAlert development
CREATE OR REPLACE VIEW V_BED AS
SELECT b.id_bed,
       b.code_bed,
       b.id_room,
       b.id_bed_type,
       b.flg_type,
       b.flg_status,
       b.desc_bed,
       b.notes,
       b.rank,
       b.flg_available,
       b.flg_schedulable,
       b.dt_creation,
	   b.flg_selected_specialties
  FROM bed b;
-- CHANGE END: Amanda Lee