--Changes by: Diamantino Campos
--Date: 29-04-2011
--Reason: APS-1538
CREATE OR REPLACE VIEW V_SCHEDULABLE_ROOMS AS
SELECT d.id_institution,
       r.id_department,
       r.id_room,
       r.flg_schedulable,
       nvl(r.desc_room,
           (SELECT pk_translation.get_translation(il.id_language, r.code_room)
              FROM institution_language il
             WHERE il.id_institution = d.id_institution)) name,
       decode(r.flg_available, 'Y', 'A', 'I') flg_available_sch,
       id_room_type
  FROM room r
  JOIN department d
    ON d.id_department = r.id_department;
-- CHANGE END: DC
