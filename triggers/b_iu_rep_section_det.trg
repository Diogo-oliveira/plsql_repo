CREATE OR REPLACE TRIGGER B_IU_REP_SECTION_DET
 BEFORE INSERT OR UPDATE OF ID_REP_SECTION_DET, ID_REP_SECTION, ID_REPORTS, ID_SOFTWARE
 ON REP_SECTION_DET
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin
  :new.adw_last_update := sysdate;
end;
/