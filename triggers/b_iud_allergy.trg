CREATE OR REPLACE
TRIGGER B_IUD_ALLERGY
 BEFORE DELETE OR INSERT OR UPDATE
 ON ALLERGY
 FOR EACH ROW
-- PL/SQL Block
BEGIN
    IF inserting
    THEN
        :NEW.code_allergy := 'ALLERGY.CODE_ALLERGY.' || :NEW.id_allergy;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN

		delete from translation
		where code_translation = :OLD.code_allergy;

     ELSIF updating
    THEN
        :NEW.code_allergy    := 'ALLERGY.CODE_ALLERGY.' || :OLD.id_allergy;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
