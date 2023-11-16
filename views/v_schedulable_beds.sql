CREATE OR REPLACE VIEW V_SCHEDULABLE_BEDS AS
SELECT d.id_institution,
       b.id_bed,
       b.id_bed_type,
       d.id_dept,
       d.id_department,
       b.flg_schedulable,
       b.id_room,
       nvl(b.desc_bed,
           (SELECT pk_translation.get_translation(il.id_language, b.code_bed)
              FROM institution_language il
             WHERE il.id_institution = d.id_institution)) name,
       decode(b.flg_available, 'Y', 'A', 'I') flg_available_sch
  FROM bed b
  JOIN room r
    ON r.id_room = b.id_room
  JOIN department d
    ON d.id_department = r.id_department;
