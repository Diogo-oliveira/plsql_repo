-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 16-03-2010
-- CHANGE REASON: SCH-410
create or replace trigger A_IU_ROOM_DEP_CLIN_SERV
  after insert or delete on ROOM_DEP_CLIN_SERV
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.room_dep_clin_serv_new(:NEW.id_room_dep_clin_serv);
  elsif deleting then
    pk_ia_event_backoffice.room_dep_clin_serv_delete(:OLD.id_room_dep_clin_serv, :OLD.id_room, :OLD.id_dep_clin_serv);
  end if;
END A_IU_ROOM_DEP_CLIN_SERV;
/
-- CHANGE END: Telmo Castro