CREATE OR REPLACE TRIGGER B_IU_DRUG_DEP_CLIN_SERV
 BEFORE INSERT OR UPDATE
 ON DRUG_DEP_CLIN_SERV
 FOR EACH ROW
-- PL/SQL Block
BEGIN
:NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/
