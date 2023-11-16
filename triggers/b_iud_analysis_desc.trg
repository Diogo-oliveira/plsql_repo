CREATE OR REPLACE
TRIGGER b_iud_analysis_desc
    BEFORE DELETE OR UPDATE OR INSERT ON analysis_desc
    FOR EACH ROW
BEGIN

    IF inserting
    THEN
        :NEW.code_analysis_desc := 'ANALYSIS_DESC.CODE_ANALYSIS_DESC.' || :NEW.id_analysis_desc;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_analysis_desc;
    ELSIF updating
    THEN
        :NEW.code_analysis_desc := 'ANALYSIS_DESC.CODE_ANALYSIS_DESC.' || :OLD.id_analysis_desc;
        :NEW.adw_last_update    := SYSDATE;
    END IF;

END b_iud_analysis_desc;
/
