create or replace trigger B_IU_COUNTRY_COMPANY
  before insert or update on country_company  
  for each row
DECLARE
    -- local variables here
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_iu_country_company;
/
