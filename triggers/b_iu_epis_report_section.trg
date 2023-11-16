CREATE OR REPLACE TRIGGER B_IU_EPIS_REPORT_SECTION
 BEFORE INSERT OR UPDATE OF ID_EPIS_REPORT, ID_EPIS_REPORT_SECTION, ID_REP_SECTION_DET
 ON EPIS_REPORT_SECTION
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin
  :new.adw_last_update := sysdate;
end;
/
