CREATE OR REPLACE TRIGGER B_IU_REP_PROF_EXCEPTION
 BEFORE INSERT OR UPDATE OF ID_INSTITUTION, ID_REP_PROF_EXCEPTION, ID_PROFESSIONAL, ID_SOFTWARE, ID_REPORTS, FLG_TYPE
 ON ALERT.REP_PROF_EXCEPTION 
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW

-- PL/SQL Block
begin
  :new.adw_last_update := sysdate;
end;
/