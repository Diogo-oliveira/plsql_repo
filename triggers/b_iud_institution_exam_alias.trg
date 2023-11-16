-- CHANGED BY: José Castro
-- CHANGE DATE: 14/12/2010 10:50
-- CHANGE REASON: ALERT-149001
CREATE OR REPLACE TRIGGER b_iud_institution_exam_alias
    BEFORE DELETE OR INSERT OR UPDATE ON exam_alias
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        IF :new.id_institution IS NOT NULL
           AND (:new.id_software IS NULL OR :new.id_software = 0)
           AND (:new.id_professional IS NULL OR :new.id_professional = 0)
           AND (:new.id_dep_clin_serv IS NULL OR :new.id_dep_clin_serv = 0)
        THEN
            intf_alert.pk_ia_event_image.institution_exam_alias_new(:new.id_exam_alias, :new.id_exam, :new.id_institution);
        END IF;
    ELSIF updating
    THEN
        IF :new.id_institution IS NOT NULL
           AND (:new.id_software IS NULL OR :new.id_software = 0)
           AND (:new.id_professional IS NULL OR :new.id_professional = 0)
           AND (:new.id_dep_clin_serv IS NULL OR :new.id_dep_clin_serv = 0)
        THEN
            intf_alert.pk_ia_event_image.institution_exam_alias_update(:new.id_exam_alias, :new.id_exam, :new.id_institution);
        END IF;
    ELSIF deleting
    THEN
        IF :old.id_institution IS NOT NULL
           AND (:old.id_software IS NULL OR :old.id_software = 0)
           AND (:old.id_professional IS NULL OR :old.id_professional = 0)
           AND (:old.id_dep_clin_serv IS NULL OR :old.id_dep_clin_serv = 0)
        THEN
            intf_alert.pk_ia_event_image.institution_exam_alias_delete(:old.id_exam_alias, :old.id_exam, :old.id_institution);
        END IF;
    END IF;
END;
/
-- CHANGED END: José Castro

-- CHANGED BY: José Castro
-- CHANGE DATE: 24/11/2010 16:50
-- CHANGE REASON: ALERT-138230
-- Removed reference to schema intf_alert
CREATE OR REPLACE TRIGGER b_iud_institution_exam_alias
    BEFORE DELETE OR INSERT OR UPDATE ON exam_alias
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        IF :new.id_institution IS NOT NULL
           AND (:new.id_software IS NULL OR :new.id_software = 0)
           AND (:new.id_professional IS NULL OR :new.id_professional = 0)
           AND (:new.id_dep_clin_serv IS NULL OR :new.id_dep_clin_serv = 0)
        THEN
            pk_ia_event_image.institution_exam_alias_new(:new.id_exam_alias, :new.id_exam, :new.id_institution);
        END IF;
    ELSIF updating
    THEN
        IF :new.id_institution IS NOT NULL
           AND (:new.id_software IS NULL OR :new.id_software = 0)
           AND (:new.id_professional IS NULL OR :new.id_professional = 0)
           AND (:new.id_dep_clin_serv IS NULL OR :new.id_dep_clin_serv = 0)
        THEN
            pk_ia_event_image.institution_exam_alias_update(:new.id_exam_alias, :new.id_exam, :new.id_institution);
        END IF;
    ELSIF deleting
    THEN
        IF :old.id_institution IS NOT NULL
           AND (:old.id_software IS NULL OR :old.id_software = 0)
           AND (:old.id_professional IS NULL OR :old.id_professional = 0)
           AND (:old.id_dep_clin_serv IS NULL OR :old.id_dep_clin_serv = 0)
        THEN
            pk_ia_event_image.institution_exam_alias_delete(:old.id_exam_alias, :old.id_exam, :old.id_institution);
        END IF;
    END IF;
END;
/
-- CHANGED END: José Castro
