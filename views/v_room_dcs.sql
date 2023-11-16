-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 22-11-2010
-- CHANGE REASON: ALERT-142288: [INPATIENT]: APS/SCH - Data Migration  
CREATE OR REPLACE VIEW V_ROOM_DCS AS 
SELECT d.id_institution,
       r.id_room,
       r.desc_room,
       r.code_room,
       r.id_room_type,
       r.id_department,
       CAST(COLLECT(to_number(rdcs.id_dep_clin_serv)) AS table_number) coll_id_dep_clin_serv,       
       decode(r.flg_available, 'Y', 'A', 'I') flg_available_sch
  FROM room_dep_clin_serv rdcs
  JOIN room r
    ON r.id_room = rdcs.id_room
  JOIN department d
    ON d.id_department = r.id_department
    GROUP BY d.id_institution, r.id_room, r.desc_room, r.code_room, r.id_room_type, r.id_department, r.flg_available;
-- CHANGE END: Sofia Mendes