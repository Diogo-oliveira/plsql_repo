create or replace trigger A_IUD_SCH_RESCHED_REASON
  after insert or update or delete on SCH_RESCHED_REASON
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.sch_reschedule_reason_new(:NEW.id_resched_reason);
  elsif updating then
			   pk_ia_event_backoffice.sch_reschedule_reason_update(:NEW.id_resched_reason);
  elsif deleting then
    pk_ia_event_backoffice.sch_reschedule_reason_delete(:OLD.id_resched_reason);
  end if;
END A_IUD_SCH_RESCHED_REASON;
/
