CREATE OR REPLACE
TRIGGER B_IU_PROF_TEAM_DET
 BEFORE INSERT OR UPDATE
 ON PROF_TEAM_DET
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
-- PL/SQL Block
begin

   :new.adw_last_update := sysdate;
end;
/
