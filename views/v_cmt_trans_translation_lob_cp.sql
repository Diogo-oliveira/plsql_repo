-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 06/07/2018 12:15
-- CHANGE REASON: [EMR-4176]
DECLARE
    l_tmp NUMBER;
BEGIN

    SELECT COUNT(*)
      INTO l_tmp
      FROM all_objects
     WHERE object_name = 'V_CMT_TRANS_TRANSLATION_LOB_CP'
       AND object_type = 'VIEW';

    IF l_tmp = 1
    THEN
        EXECUTE IMMEDIATE 'DROP VIEW ALERT.V_CMT_TRANS_TRANSLATION_LOB_CP';
    END IF;
END;
/
-- CHANGE END: Luis Fernandes