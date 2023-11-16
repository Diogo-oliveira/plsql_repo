CREATE OR REPLACE VIEW V_ROOM_TYPE AS
SELECT rt.id_room_type, rt.code_room_type, rt.flg_available
  FROM room_type rt;


-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-386
create or replace view v_room_type as
select rt.id_room_type,
       rt.code_room_type,
       rt.flg_available,
       rt.id_institution
  from room_type rt;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 22-11-2010
-- CHANGE REASON: ALERT-142288: [INPATIENT]: APS/SCH - Data Migration
create or replace view v_room_type as
select rt.id_room_type,
       rt.code_room_type,
       rt.flg_available,
       rt.id_institution,
       rt.desc_room_type,
       decode(rt.flg_available, 'Y', 'A', 'I') flg_available_sch
  from room_type rt;
-- CHANGE END: Sofia Mendes