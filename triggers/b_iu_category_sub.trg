CREATE OR REPLACE
TRIGGER b_iu_category_sub
    BEFORE INSERT OR UPDATE OF id_category_sub, id_category, code_category_sub, flg_available, flg_type ON alert.category_sub
    REFERENCING NEW AS NEW OLD AS OLD
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_category_sub := 'CATEGORY_SUB.CODE_CATEGORY_SUB.' || :NEW.id_category_sub;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_category_sub;
    ELSIF updating
    THEN
        :NEW.code_category_sub := 'CATEGORY_SUB.CODE_CATEGORY_SUB.' || :OLD.id_category_sub;
    END IF;
END;
/
