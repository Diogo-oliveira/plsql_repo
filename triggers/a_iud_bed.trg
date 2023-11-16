-- CHANGED BY: Telmo
-- CHANGE DATE: 27-08-2014
-- CHANGE REASON: ALERT-293585
create or replace trigger A_IUD_BED
  after insert or update or delete on BED
  for each row
BEGIN
    if inserting then
      pk_ia_event_backoffice.bed_new(:NEW.id_bed);
    elsif updating then
      pk_ia_event_backoffice.bed_update(:NEW.id_bed);
    elsif deleting then
    	pk_ia_event_backoffice.bed_delete(:OLD.id_bed,:OLD.id_room);
    end if;
END A_IUD_BED;
-- END CHANGE: Telmo
