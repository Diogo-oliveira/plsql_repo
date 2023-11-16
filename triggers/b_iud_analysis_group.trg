CREATE OR REPLACE
TRIGGER B_IUD_ANALYSIS_GROUP
 BEFORE DELETE OR INSERT OR UPDATE
 ON ANALYSIS_GROUP
 FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :NEW.code_analysis_group := 'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' || :NEW.id_analysis_group;


        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
       delete from translation
		where code_translation = :OLD.code_analysis_group;
    ELSIF updating
    THEN
        :NEW.code_analysis_group := 'ANALYSIS_GROUP.CODE_ANALYSIS_GROUP.' || :OLD.id_analysis_group;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
