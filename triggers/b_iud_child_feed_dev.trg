CREATE OR REPLACE
TRIGGER b_iud_child_feed_dev
    BEFORE DELETE OR INSERT OR UPDATE ON child_feed_dev
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_child_feed_dev := 'CHILD_FEED_DEV.CODE_CHILD_FEED_DEV.' || :NEW.id_child_feed_dev;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_child_feed_dev;
    ELSIF updating
    THEN
        :NEW.code_child_feed_dev := 'CHILD_FEED_DEV.CODE_CHILD_FEED_DEV.' || :OLD.id_child_feed_dev;
        :NEW.adw_last_update     := SYSDATE;
    END IF;
END;
/
