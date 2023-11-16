-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_388
create or replace trigger A_IUD_DEP_CLIN_SERV
  after insert or update of flg_available or delete on DEP_CLIN_SERV
  for each row
BEGIN
  if inserting then
    pk_ia_event_backoffice.dep_clin_serv_new(:NEW.id_dep_clin_serv);
  elsif updating then
    if :NEW.flg_available = 'Y' then
      pk_ia_event_backoffice.dep_clin_serv_enable(:NEW.id_dep_clin_serv);
    elsif :NEW.flg_available = 'N' then
      pk_ia_event_backoffice.dep_clin_serv_disable(:NEW.id_dep_clin_serv);
    end if;
  elsif deleting then
    pk_ia_event_backoffice.dep_clin_serv_delete(:OLD.id_dep_clin_serv, :OLD.id_department, :OLD.id_clinical_service);
  end if;
END A_IUD_DEP_CLIN_SERV;
/
-- CHANGE END: Telmo Castro