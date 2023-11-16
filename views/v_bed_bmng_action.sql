-- CHANGED BY: Luís Maia
-- CHANGE DATE: 08/06/2011 16:36
-- CHANGE REASON: [ALERT-184131] New view for bed management
CREATE OR REPLACE VIEW v_bed_bmng_action AS
SELECT ba.id_bmng_action,
       ba.id_room,
       ba.id_bed,
       ba.id_bmng_reason,
       ba.id_bmng_reason_type,
       ba.id_bmng_allocation_bed,
       ba.flg_target_action,
       ba.flg_status,
       ba.flg_origin_action,
       ba.flg_bed_ocupacity_status,
       ba.flg_bed_status,
       ba.flg_bed_cleaning_status,
       ba.id_prof_creation,
       ba.dt_creation,
       ba.nch_capacity,
       ba.action_notes,
       ba.dt_begin_action,
       ba.dt_end_action,
       ba.id_department,
       ba.id_cancel_reason,
       ba.flg_action,
       --partitioning by last action: rn = 1 is last known, rn = 2 is second last
       row_number() OVER(PARTITION BY ba.id_bed ORDER BY ba.dt_creation DESC) action_rank
  FROM bmng_action ba;
-- CHANGE END: Luís Maia
