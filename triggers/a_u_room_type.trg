-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_U_ROOM_TYPE
  after update of flg_available on ROOM_TYPE
  for each row
BEGIN
  if :NEW.flg_available = 'Y' then
    pk_ia_event_backoffice.room_type_enable(:NEW.id_room_type);
  elsif :NEW.flg_available = 'N' then
    pk_ia_event_backoffice.room_type_disable(:NEW.id_room_type);
  end if;
END A_U_ROOM_TYPE;
/
-- CHANGE END: Telmo Castro