CREATE OR REPLACE
TRIGGER b_iud_geo_location
    BEFORE DELETE OR INSERT OR UPDATE ON geo_location
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_geo_location := 'GEO_LOCATION.CODE_GEO_LOCATION.' || :NEW.id_geo_location;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_geo_location;
    ELSIF updating
    THEN
        :NEW.code_geo_location := 'GEO_LOCATION.CODE_GEO_LOCATION.' || :OLD.id_geo_location;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
