CREATE OR REPLACE
TRIGGER B_IU_ANALYSIS_INSTIT_SOFT
 BEFORE INSERT OR UPDATE
 ON ANALYSIS_INSTIT_SOFT
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
    :NEW.adw_last_update := SYSDATE;

    IF :NEW.id_analysis IS NULL
       AND :NEW.id_analysis_group IS NULL
    THEN
        raise_application_error(-20000, 'id analysis and id analysis group cannot be null at same time.');

    END IF;

-- REMOVED because of Backoffice edition of analysis that could not define an exam cat at this time
/**   IF :NEW.id_analysis IS NOT NULL
       AND :NEW.id_exam_cat IS NULL
    THEN
        raise_application_error(-20000, 'id exam cat cannot be null if id analysis is not null .');
    END IF;*/
END;
/
