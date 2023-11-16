
CREATE OR REPLACE TRIGGER a_d_geo_state
    AFTER DELETE ON geo_state
    FOR EACH ROW
BEGIN
    DELETE FROM translation WHERE code_translation = :OLD.code_geo_state;
    DELETE FROM translation WHERE code_translation = :OLD.code_geo_state_abbr;
END;
/
