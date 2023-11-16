CREATE OR REPLACE
TRIGGER B_IUD_DOC_COMPONENT
 BEFORE DELETE OR INSERT OR UPDATE
 ON DOC_COMPONENT
 FOR EACH ROW
-- PL/SQL Block
BEGIN
    IF inserting
    THEN
        :NEW.adw_last_update := SYSDATE;
    ELSIF updating
    THEN
        :NEW.adw_last_update    := SYSDATE;
    END IF;
END;
/

-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 14/12/2011 10:52
-- CHANGE REASON: [ALERT-209821] Remove unnecessary triggers in metadata tables for Touch-option templates
DECLARE
    l_exists NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO l_exists
      FROM user_objects uo
     WHERE uo.object_name = 'B_IUD_DOC_COMPONENT'
       AND uo.object_type = 'TRIGGER';
    IF l_exists = 1
    THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER B_IUD_DOC_COMPONENT';
    END IF;
END;
/
-- CHANGE END: Ariel Machado