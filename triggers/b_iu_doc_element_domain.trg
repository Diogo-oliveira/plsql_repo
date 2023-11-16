CREATE OR REPLACE TRIGGER B_IU_DOC_ELEMENT_DOMAIN
BEFORE INSERT OR UPDATE ON DOC_ELEMENT_DOMAIN
FOR EACH ROW
BEGIN
   :NEW.ADW_LAST_UPDATE := SYSDATE;
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
     WHERE uo.object_name = 'B_IU_DOC_ELEMENT_DOMAIN'
       AND uo.object_type = 'TRIGGER';
    IF l_exists = 1
    THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER B_IU_DOC_ELEMENT_DOMAIN';
    END IF;
END;
/
-- CHANGE END: Ariel Machado