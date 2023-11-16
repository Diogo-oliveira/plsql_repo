CREATE OR REPLACE TRIGGER B_IU_ALLERGY_INST_SOFT
 BEFORE INSERT OR UPDATE
 ON ALLERGY_INST_SOFT
 FOR EACH ROW
BEGIN
    :NEW.ADW_LAST_UPDATE := SYSDATE;
END;
/