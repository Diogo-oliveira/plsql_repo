-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 12-03-2010
-- CHANGE REASON: SCH-410

create or replace trigger A_U_EXAM
  after update of flg_available on EXAM
  for each row
BEGIN
  if :NEW.flg_available = 'Y' then
    pk_ia_event_backoffice.exam_enable(:NEW.id_exam);
  elsif :NEW.flg_available = 'N' then
    pk_ia_event_backoffice.exam_disable(:NEW.id_exam);
  end if;
END A_U_EXAM;
/
-- CHANGE END: Telmo Castro