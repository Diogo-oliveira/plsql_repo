CREATE OR REPLACE TRIGGER B_IU_REP_PROFILE_TEMPLATE
 BEFORE INSERT OR UPDATE OF ID_SOFTWARE, ID_INSTITUTION, INTERNAL_NAME, ID_REP_PROFILE_TEMPLATE
 ON REP_PROFILE_TEMPLATE
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin
  :new.adw_last_update := sysdate;
end;
/
