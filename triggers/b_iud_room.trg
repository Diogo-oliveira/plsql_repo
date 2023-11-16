CREATE OR REPLACE
TRIGGER b_iud_room
    BEFORE DELETE OR INSERT OR UPDATE ON room
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_room         := 'ROOM.CODE_ROOM.' || :NEW.id_room;
        :NEW.code_abbreviation := 'ROOM.CODE_ABBREVIATION.' || :NEW.id_room;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_room
            OR code_translation = :OLD.code_abbreviation;
    ELSIF updating
    THEN
        :NEW.code_room         := 'ROOM.CODE_ROOM.' || :OLD.id_room;
        :NEW.code_abbreviation := 'ROOM.CODE_ABBREVIATION.' || :OLD.id_room;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
