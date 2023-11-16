-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_388
create or replace trigger A_ID_SCH_EVENT_DCS
  after insert or delete on SCH_EVENT_DCS
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.sch_event_dcs_new(:NEW.id_sch_event_dcs);
  elsif deleting then
    pk_ia_event_backoffice.sch_event_dcs_delete(:OLD.id_sch_event_dcs, :OLD.id_sch_event, :OLD.id_dep_clin_serv);
  end if;
END A_ID_SCH_EVENT_DCS;
/
-- CHANGE END: Telmo Castro

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 20-05-2010
-- CHANGE REASON: ALERT-98534
drop trigger ALERT.A_ID_SCH_EVENT_DCS;
-- END CHANGE: Telmo Castro
