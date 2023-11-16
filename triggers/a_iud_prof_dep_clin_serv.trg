-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_388
create or replace trigger A_IUD_PROF_DEP_CLIN_SERV
  after insert or update or delete on PROF_DEP_CLIN_SERV
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.prof_dep_clin_serv_new(:NEW.id_institution, :NEW.id_prof_dep_clin_serv);
  elsif updating then
    pk_ia_event_backoffice.prof_dep_clin_serv_update(:NEW.id_institution, :NEW.id_prof_dep_clin_serv);
  elsif deleting then
    pk_ia_event_backoffice.prof_dep_clin_serv_delete(:OLD.id_institution, :OLD.id_prof_dep_clin_serv,i_id_professional => :OLD.id_professional,i_id_dep_clin_serv => :OLD.id_dep_clin_serv);
  end if;
END A_IUD_PROF_DEP_CLIN_SERV;
/
-- CHANGE END: Telmo Castro

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 25/06/2018 12:15
-- CHANGE REASON: [EMR-4423]
DROP TRIGGER ALERT.A_IUD_PROF_DEP_CLIN_SERV;
-- CHANGE END: Luis Fernandes