CREATE OR REPLACE
TRIGGER B_IUD_ANALYSIS_ALIAS
 BEFORE DELETE OR INSERT OR UPDATE
 ON ANALYSIS_ALIAS
 FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_analysis_alias := 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || :NEW.id_analysis_alias;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
     delete from translation
		where code_translation = :OLD.code_analysis_alias;
    ELSIF updating
    THEN
        :NEW.code_analysis_alias := 'ANALYSIS_ALIAS.CODE_ANALYSIS_ALIAS.' || :OLD.id_analysis_alias;
        :NEW.adw_last_update     := SYSDATE;

    END IF;
END;
/
