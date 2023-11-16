-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 10-10-2010
-- CHANGE REASON: ALERT-131275

create or replace trigger A_IUD_NO_SHOW_REASON
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
END A_IUD_NO_SHOW_REASON;
-- CHANGE END: Rita Lopes

-- CHANGED BY: Rita Lopes
-- CHANGE DATE: 10-10-2010
-- CHANGE REASON: ALERT-131275
drop trigger A_IUD_NO_SHOW_REASON;
create or replace trigger A_IUD_NO_SHOW_REASON
  after insert or update or delete on CANCEL_REASON
  for each row
DECLARE
    l_count              NUMBER;
    l_id_cancel_rea_area cancel_reason.id_cancel_rea_area%TYPE;

BEGIN

    IF inserting
    THEN
        l_id_cancel_rea_area := :NEW.id_cancel_rea_area;
    ELSIF updating
          OR deleting
    THEN
        l_id_cancel_rea_area := :OLD.id_cancel_rea_area;
    END IF;

    SELECT COUNT(*)
      INTO l_count
      FROM cancel_rea_area cra
     WHERE cra.id_cancel_rea_area = l_id_cancel_rea_area
       AND cra.intern_name = 'PATIENT_NO_SHOW';

    IF l_count > 0
    THEN
        IF inserting
        THEN
            pk_ia_event_backoffice.noshow_reason_new(:NEW.id_cancel_reason);
        ELSIF updating
        THEN
            pk_ia_event_backoffice.noshow_reason_update(:NEW.id_cancel_reason);
        ELSIF deleting
        THEN
            pk_ia_event_backoffice.noshow_reason_delete(:OLD.id_cancel_reason);
        END IF;
    END IF;
END a_iud_no_show_reason;
-- CHANGE END

-- CHANGED BY: Sergio Dias
-- CHANGE DATE: 29-04-2011
-- CHANGE REASON: ALERT-175337
drop trigger A_IUD_NO_SHOW_REASON;
-- CHANGE END
/
