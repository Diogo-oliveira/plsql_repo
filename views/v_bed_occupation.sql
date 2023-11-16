-- CHANGED BY: Luís Maia
-- CHANGE DATE: 08/06/2011 16:36
-- CHANGE REASON: [ALERT-184131] New view for bed management
CREATE OR REPLACE VIEW v_bed_occupation AS
SELECT ea.id_bmng_action,
       ea.id_bed,
       ea.dt_begin,
       ea.dt_end,
       ea.id_bmng_reason_type,
       ea.id_bmng_reason,
       ea.id_episode,
       ea.id_patient,
       ea.id_room,
       ea.id_admission_type,
       ea.id_room_type,
       ea.id_bmng_allocation_bed,
       ea.id_bed_type,
       ea.dt_discharge_schedule,
       ea.flg_allocation_nch,
       ea.id_nch_level,
       ea.flg_bed_ocupacity_status,
       ea.flg_bed_status,
       ea.flg_bed_cleaning_status,
       ea.has_notes,
       ea.flg_bed_type,
       ea.id_department
  FROM bmng_bed_ea ea;
-- CHANGE END: Luís Maia
