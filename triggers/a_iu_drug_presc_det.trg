CREATE OR REPLACE TRIGGER A_IU_DRUG_PRESC_DET
  AFTER INSERT OR UPDATE OF FLG_STATUS ON DRUG_PRESC_DET  
  FOR EACH ROW
DECLARE
    -- local variables here
    l_status_canceled     CONSTANT VARCHAR2(1) := PK_MEDICATION_CURRENT.G_DET_CAN;--'C'
    l_status_discontinued CONSTANT VARCHAR2(1) := PK_MEDICATION_CURRENT.G_DET_INTR;--'I'
		l_status_completed    CONSTANT VARCHAR2(1) := PK_MEDICATION_CURRENT.G_DET_FIN;--'F'
BEGIN
    IF (inserting) THEN
        -- DRUG_PRESCRIPTION_NEW
        pk_ia_event_prescription.drug_prescription_new(i_id_drug_presc_det => :NEW.id_drug_presc_det);
    ELSIF (updating) THEN
        IF (:OLD.flg_status <> l_status_canceled AND :NEW.flg_status = l_status_canceled) THEN
            -- DRUG_PRESCRIPTION_CANCELLED
            pk_ia_event_prescription.drug_prescription_cancelled(i_id_drug_presc_det => :NEW.id_drug_presc_det);
        ELSIF (:OLD.flg_status <> l_status_discontinued AND :NEW.flg_status = l_status_discontinued) THEN
            -- DRUG_PRESCRIPTION_DISCONTINUED
            pk_ia_event_prescription.drug_prescription_discontinued(i_id_drug_presc_det => :NEW.id_drug_presc_det);
        ELSIF (:OLD.flg_status <> l_status_completed AND :NEW.flg_status = l_status_completed) THEN
            -- DRUG_PRESCRIPTION_COMPLETED
            pk_ia_event_prescription.drug_prescription_completed(i_id_drug_presc_det => :NEW.id_drug_presc_det);
        END IF;
    END IF;
END TRG_AIU_DRUG_PRESC_DET;
/


-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 28/11/2013 10:41
-- CHANGE REASON: [ALERT-270757] Medication Events DDL
drop trigger A_IU_DRUG_PRESC_DET;
-- CHANGE END: Gustavo Serrano