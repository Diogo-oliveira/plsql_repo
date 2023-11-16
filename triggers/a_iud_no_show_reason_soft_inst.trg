-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 10-10-2010
-- CHANGE REASON: ALERT-134162
create or replace trigger A_IUD_NO_SHOW_REASON_SOFT_INST
  after insert or update or delete on CANCEL_REA_SOFT_INST
  for each row
DECLARE
    l_count            NUMBER;
    l_id_cancel_reason cancel_rea_soft_inst.id_cancel_reason%TYPE;

BEGIN

    IF inserting
    THEN
        l_id_cancel_reason := :NEW.id_cancel_reason;
    ELSIF updating
          OR deleting
    THEN
        l_id_cancel_reason := :OLD.id_cancel_reason;
    END IF;

    SELECT COUNT(*)
      INTO l_count
      FROM cancel_reason cr, cancel_rea_area cra
     WHERE cr.id_cancel_reason = l_id_cancel_reason
       AND cr.id_cancel_rea_area = cra.id_cancel_rea_area
       AND cra.intern_name = 'PATIENT_NO_SHOW';

    IF l_count > 0
    THEN
        IF inserting
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_new(:NEW.id_cancel_reason,
                                                               :NEW.id_profile_template,
                                                               :NEW.id_software,
                                                               :NEW.id_institution);
        ELSIF updating
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_update(:NEW.id_cancel_reason,
                                                                  :NEW.id_profile_template,
                                                                  :NEW.id_software,
                                                                  :NEW.id_institution);
        ELSIF deleting
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_delete(:OLD.id_cancel_reason,
                                                                  :OLD.id_profile_template,
                                                                  :OLD.id_software,
                                                                  :OLD.id_institution);
        END IF;
    END IF;
END a_iud_no_show_reason_soft_inst;
-- CHANGE END

-- CHANGED BY: Sergio Dias
-- CHANGE DATE: 29-04-2011
-- CHANGE REASON: ALERT-175337
create or replace trigger A_IUD_NO_SHOW_REASON_SOFT_INST
  after insert or update or delete on CANCEL_REA_SOFT_INST
  for each row
DECLARE
    l_count                 NUMBER;
    l_id_cancel_reason_area cancel_rea_soft_inst.id_cancel_rea_area%TYPE;

BEGIN

    IF inserting
    THEN
        l_id_cancel_reason_area := :NEW.id_cancel_rea_area;
    ELSIF updating
          OR deleting
    THEN
        l_id_cancel_reason_area := :OLD.id_cancel_rea_area;
    END IF;

    SELECT COUNT(*)
      INTO l_count
      FROM cancel_rea_area cra
     WHERE l_id_cancel_reason_area = cra.id_cancel_rea_area
       AND cra.intern_name = 'PATIENT_NO_SHOW';

    IF l_count > 0
    THEN
        IF inserting
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_new(:NEW.id_cancel_reason,
                                                               :NEW.id_profile_template,
                                                               :NEW.id_software,
                                                               :NEW.id_institution);
        ELSIF updating
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_update(:NEW.id_cancel_reason,
                                                                  :NEW.id_profile_template,
                                                                  :NEW.id_software,
                                                                  :NEW.id_institution);
        ELSIF deleting
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_delete(:OLD.id_cancel_reason,
                                                                  :OLD.id_profile_template,
                                                                  :OLD.id_software,
                                                                  :OLD.id_institution);
        END IF;
    END IF;
END a_iud_no_show_reason_soft_inst;
-- CHANGE END

-- CHANGED BY: Jorge Silva
-- CHANGE DATE: 07-03-2014
-- CHANGE REASON: ALERT-278273
CREATE OR REPLACE TRIGGER a_iud_no_show_reason_soft_inst
    AFTER INSERT OR UPDATE OR DELETE ON cancel_rea_soft_inst
    FOR EACH ROW
DECLARE
    l_count              NUMBER;
    l_id_institution     institution.id_institution%TYPE;
    l_id_cancel_rea_area cancel_rea_soft_inst.id_cancel_rea_area%TYPE;
BEGIN

    IF inserting
    THEN
        l_id_institution     := :new.id_institution;
        l_id_cancel_rea_area := :new.id_cancel_rea_area;
    ELSIF updating
          OR deleting
    THEN
        l_id_institution     := :old.id_institution;
        l_id_cancel_rea_area := :old.id_cancel_rea_area;
    END IF;

    SELECT COUNT(*)
      INTO l_count
      FROM cancel_reason cr
      LEFT JOIN reason_synonym_inst rsi
        ON rsi.id_reason = cr.id_cancel_reason
       AND rsi.id_institution = l_id_institution
      JOIN reason_action_relation rar
        ON rar.id_reason = cr.id_cancel_reason
      JOIN reason_action ra
        ON ra.id_action = rar.id_action
       AND ra.flg_type = 'C'
      JOIN cancel_rea_area cra
        ON cra.id_cancel_rea_area = l_id_cancel_rea_area
     WHERE upper(cra.intern_name) = upper('PATIENT_NO_SHOW');

    IF l_count > 0
    THEN
        IF inserting
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_new(:new.id_cancel_reason,
                                                               :new.id_profile_template,
                                                               :new.id_software,
                                                               :new.id_institution);
        ELSIF updating
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_update(:new.id_cancel_reason,
                                                                  :new.id_profile_template,
                                                                  :new.id_software,
                                                                  :new.id_institution);
        ELSIF deleting
        THEN
            pk_ia_event_backoffice.noshow_reason_soft_inst_delete(:old.id_cancel_reason,
                                                                  :old.id_profile_template,
                                                                  :old.id_software,
                                                                  :old.id_institution);
        END IF;
    END IF;
END a_iud_no_show_reason_soft_inst;
-- CHANGE END

-- CHANGED BY: Miguel Monteiro
-- CHANGE DATE: 04-03-2020
-- CHANGE REASON: EMR-27407
drop trigger a_iud_no_show_reason_soft_inst;
-- CHANGE END
/
