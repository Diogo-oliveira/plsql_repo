CREATE OR REPLACE
TRIGGER B_IUD_BUILDING
 BEFORE DELETE OR INSERT OR UPDATE
 ON BUILDING
 FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_building := 'BUILDING.CODE_BUILDING.' || :NEW.id_building;


        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
       delete from translation
		where code_translation = :OLD.code_building;
    ELSIF updating
    THEN
        :NEW.code_building   := 'BUILDING.CODE_BUILDING.' || :OLD.id_building;
        :NEW.adw_last_update := SYSDATE;
    END IF;
END;
/
