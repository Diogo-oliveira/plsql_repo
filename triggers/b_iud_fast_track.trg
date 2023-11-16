CREATE OR REPLACE
TRIGGER b_iud_fast_track
    BEFORE DELETE OR INSERT OR UPDATE ON fast_track
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_fast_track := 'FAST_TRACK.CODE_FAST_TRACK.' || :NEW.id_fast_track;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_fast_track;
    ELSIF updating
    THEN
        :NEW.code_fast_track := 'FAST_TRACK.CODE_FAST_TRACK.' || :OLD.id_fast_track;
    END IF;

END b_iud_fast_track;
/
