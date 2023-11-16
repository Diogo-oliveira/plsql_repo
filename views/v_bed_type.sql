CREATE OR REPLACE VIEW V_BED_TYPE AS
SELECT bt.id_bed_type, bt.code_bed_type, bt.flg_available, bt.id_institution
  FROM bed_type bt;


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 22-11-2010
-- CHANGE REASON: ALERT-142288: [INPATIENT]: APS/SCH - Data Migration
CREATE OR REPLACE VIEW V_BED_TYPE AS
SELECT bt.id_bed_type,
       bt.code_bed_type,
       bt.flg_available,
       bt.id_institution,
       bt.desc_bed_type,
       decode(bt.flg_available, 'Y', 'A', 'I') flg_available_sch
  FROM bed_type bt;
-- CHANGE END: Sofia Mendes

