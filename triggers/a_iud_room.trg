-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 06-04-2010
-- CHANGE REASON: SCH-510
create or replace trigger A_IUD_ROOM
  after insert or update or delete on ROOM
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.room_new(:NEW.id_room, :NEW.id_department);
  elsif updating then
    pk_ia_event_backoffice.room_update(:NEW.id_room, :NEW.id_department);
  elsif deleting then
  	pk_ia_event_backoffice.room_delete(:OLD.id_room, :OLD.id_department);
  end if;
END A_IUD_ROOM;
/
-- CHANGE END: Telmo Castro