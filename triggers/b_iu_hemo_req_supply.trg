CREATE OR REPLACE TRIGGER B_IU_HEMO_REQ_SUPPLY
 BEFORE INSERT OR UPDATE
 ON HEMO_REQ_SUPPLY
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin
    
   :new.adw_last_update := sysdate;
end;
/
