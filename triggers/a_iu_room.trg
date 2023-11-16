-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_IU_ROOM
  after insert or update on ROOM
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.room_new(:NEW.id_room, :NEW.id_department);
  elsif updating then
    pk_ia_event_backoffice.room_update(:NEW.id_room, :NEW.id_department);
  end if;
END A_IU_ROOM;
/
-- CHANGE END: Telmo Castro