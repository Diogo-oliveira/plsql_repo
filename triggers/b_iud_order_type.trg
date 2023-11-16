CREATE OR REPLACE
TRIGGER b_iud_order_type
    BEFORE DELETE OR INSERT OR UPDATE ON alert.order_type
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_order_type := 'ORDER_TYPE.CODE_ORDER_TYPE.' || :NEW.id_order_type;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_order_type;
    ELSIF updating
    THEN
        :NEW.code_order_type := 'ORDER_TYPE.CODE_ORDER_TYPE.' || :OLD.id_order_type;

    END IF;
END;
/
