CREATE OR REPLACE
TRIGGER b_iud_graphic
    BEFORE DELETE OR INSERT OR UPDATE ON graphic
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_graphic      := 'GRAPHIC.CODE_GRAPHIC.' || :NEW.id_graphic;
        :NEW.code_x_axis_label := 'GRAPHIC.CODE_X_AXIS_LABEL.' || :NEW.id_graphic;
        :NEW.code_y_axis_label := 'GRAPHIC.CODE_Y_AXIS_LABEL.' || :NEW.id_graphic;

        :NEW.adw_last_update := SYSDATE;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_graphic
            OR code_translation = :OLD.code_x_axis_label
            OR code_translation = :OLD.code_y_axis_label;
    ELSIF updating
    THEN
        :NEW.code_x_axis_label := 'GRAPHIC.CODE_X_AXIS_LABEL.' || :OLD.id_graphic;
        :NEW.code_y_axis_label := 'GRAPHIC.CODE_Y_AXIS_LABEL.' || :OLD.id_graphic;
        :NEW.adw_last_update   := SYSDATE;
    END IF;
END;
/
