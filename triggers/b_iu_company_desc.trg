create or replace trigger B_IU_COMPANY_DESC
  before insert or update on company_desc  
  for each row
DECLARE
    -- local variables here
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_iu_company_desc;
/
