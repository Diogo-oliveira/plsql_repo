-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_U_CLINICAL_SERVICE
  after update of flg_available on CLINICAL_SERVICE
  for each row
BEGIN
  if :NEW.flg_available = 'Y' then
    pk_ia_event_backoffice.clinical_service_enable(:NEW.id_clinical_service);
  elsif :NEW.flg_available = 'N' then
    pk_ia_event_backoffice.clinical_service_disable(:NEW.id_clinical_service);
  end if;
END A_U_CLINICAL_SERVICE;
/
-- CHANGE END: Telmo Castro