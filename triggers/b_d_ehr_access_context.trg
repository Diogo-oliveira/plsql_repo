CREATE OR REPLACE TRIGGER B_IUD_EHR_ACCESS_CONTEXT
 BEFORE DELETE OR INSERT OR UPDATE
 ON EHR_ACCESS_CONTEXT
 FOR EACH ROW
-- PL/SQL Block
DECLARE
CURSOR C_LANG IS
  SELECT DISTINCT ID_LANGUAGE
  FROM LANGUAGE;
  CURSOR C_LANG_SEQ IS
    SELECT SEQ_TRANSLATION.NEXTVAL
    FROM DUAL;
  WSEQ TRANSLATION.ID_TRANSLATION%TYPE;

  CURSOR C_TRANSLATE IS
    SELECT ID_TRANSLATION
  FROM TRANSLATION
  WHERE CODE_TRANSLATION = :OLD.CODE_EHR_ACCESS_CONTEXT;
BEGIN
IF DELETING THEN
  FOR WREC_TRANSLATE IN C_TRANSLATE LOOP
    DELETE FROM TRANSLATION
    WHERE ID_TRANSLATION = WREC_TRANSLATE.ID_TRANSLATION;
  END LOOP;
  ELSIF UPDATING THEN
  :NEW.CODE_EHR_ACCESS_CONTEXT := 'EHR_ACCESS_CONTEXT.CODE_EHR_ACCESS_CONTEXT.'||:OLD.ID_EHR_ACCESS_CONTEXT;
  END IF;
END;
