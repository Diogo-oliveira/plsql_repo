-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
create or replace view v_department as
create or replace view v_dept as
SELECT d.id_dept, 
       d.code_dept, 
       d.id_institution, 
       d.abbreviation, 
       d.flg_available, 
       d.flg_priority, 
       d.flg_collection_by
  FROM dept d;
  
-- CHANGE END: Telmo Castro