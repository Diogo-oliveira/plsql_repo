CREATE OR REPLACE
TRIGGER B_IUD_ANALYSIS
 BEFORE DELETE OR INSERT OR UPDATE
 ON ANALYSIS
 FOR EACH ROW
-- PL/SQL Block
BEGIN
    IF inserting
    THEN
        :NEW.code_analysis := 'ANALYSIS.CODE_ANALYSIS.' || :NEW.id_analysis;
        :NEW.adw_last_update := SYSDATE;
    ELSIF deleting
    THEN

		delete from translation
		where code_translation = :OLD.code_analysis;

			 ELSIF updating
    THEN
        :NEW.code_analysis   := 'ANALYSIS.CODE_ANALYSIS.' || :OLD.id_analysis;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
