CREATE OR REPLACE TRIGGER B_IU_SR_SURGERY_RECORD
 BEFORE INSERT OR UPDATE
 ON SR_SURGERY_RECORD
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin

  :new.adw_last_update := sysdate;

end;
/
