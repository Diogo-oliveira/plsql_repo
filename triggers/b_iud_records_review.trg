CREATE OR REPLACE
TRIGGER b_iud_records_review
    BEFORE DELETE OR INSERT OR UPDATE ON records_review
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_records_review := 'RECORDS_REVIEW.CODE_RECORDS_REVIEW.' || :NEW.id_records_review;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_records_review;
    ELSIF updating
    THEN
        :NEW.code_records_review := 'RECORDS_REVIEW.CODE_RECORDS_REVIEW.' || :OLD.id_records_review;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
