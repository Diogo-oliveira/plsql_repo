CREATE OR REPLACE TRIGGER B_IUD_DOC_QUALIFICATION_REL
 BEFORE DELETE OR INSERT OR UPDATE
 ON DOC_QUALIFICATION_REL
 FOR EACH ROW
begin
    :NEW.adw_last_update := SYSDATE;
end;
/

-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 09/05/2011 17:49
-- CHANGE REASON: [ALERT-177558] Remove unused trigger.This trigger was trying to do an update when deleting entries.
--Remove unused trigger
DECLARE
    l_exists PLS_INTEGER;
BEGIN

    SELECT COUNT(0)
      INTO l_exists
      FROM user_triggers ut
     WHERE ut.trigger_name = 'B_IUD_DOC_QUALIFICATION_REL';

    IF l_exists > 0
    THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER B_IUD_DOC_QUALIFICATION_REL';
    END IF;

END;
/
-- CHANGE END: Ariel Machado