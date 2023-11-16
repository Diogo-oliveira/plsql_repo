create or replace trigger B_IU_INSTITUTION_LANGUAGE
  before insert or update on institution_language  
  for each row
DECLARE
    -- local variables here
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_iu_institution_language;
/
