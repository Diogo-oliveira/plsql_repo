create or replace trigger B_IU_COUNTRY_CURRENCY
  before insert or update on country_currency  
  for each row
DECLARE
    -- local variables here
BEGIN
    :NEW.adw_last_update := SYSDATE;
END b_iu_country_currency;
/
