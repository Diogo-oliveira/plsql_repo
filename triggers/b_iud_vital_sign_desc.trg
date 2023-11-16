CREATE OR REPLACE
TRIGGER b_iud_vital_sign_desc
    BEFORE DELETE OR INSERT OR UPDATE ON vital_sign_desc
    FOR EACH ROW

BEGIN
    IF inserting
    THEN
        :new.code_vital_sign_desc := 'VITAL_SIGN_DESC.CODE_VITAL_SIGN_DESC.' || :new.id_vital_sign_desc;
        :new.code_abbreviation    := 'VITAL_SIGN_DESC.CODE_ABBREVIATION.' || :new.id_vital_sign_desc;
    
    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :old.code_vital_sign_desc
            OR code_translation = :old.code_abbreviation;
    
    ELSIF updating
    THEN
        :new.code_vital_sign_desc := 'VITAL_SIGN_DESC.CODE_VITAL_SIGN_DESC.' || :old.id_vital_sign_desc;
        :new.code_abbreviation    := 'VITAL_SIGN_DESC.CODE_ABBREVIATION.' || :old.id_vital_sign_desc;
    
    END IF;

END;
/
