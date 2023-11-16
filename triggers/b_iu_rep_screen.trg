CREATE OR REPLACE TRIGGER B_IU_REP_SCREEN
 BEFORE INSERT OR UPDATE OF INTERNAL_NAME, ID_REP_SCREEN, SCREEN_NAME
 ON REP_SCREEN
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin
  :new.adw_last_update := sysdate;
end;
/
