CREATE OR REPLACE TRIGGER B_IU_EPIS_PROTOCOLS
BEFORE INSERT OR UPDATE
ON ALERT.EPIS_PROTOCOLS 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE

BEGIN
  :new.adw_last_update := sysdate;

END ;
/
