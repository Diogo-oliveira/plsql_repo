-- CHANGED BY: Ana Rita Martins
-- CHANGED DATE: 28/09/2009
-- CHANGING REASON: CODING-879 
create or replace trigger "A_IU_PAT_HISTORY_DIAGNOSIS"
  after insert or update on pat_history_diagnosis
  for each row
DECLARE
    -- local variables here
    l_status_canceled CONSTANT VARCHAR2(1) := 'C';

BEGIN
    IF (inserting)
    THEN
        -- PAT_HISTORY_DIAGNOSIS_NEW
        pk_ia_event_common.pat_diagnosis_history_new(i_id_pat_history_diagnoses => :NEW.id_pat_history_diagnosis);
    ELSIF (updating)
    THEN
        -- PAT_HISTORY_DIAGNOSIS_CANCEL
        IF (:OLD.flg_status <> l_status_canceled AND :NEW.flg_status = l_status_canceled)
        THEN
            pk_ia_event_common.pat_diagnosis_history_cancel(i_id_pat_history_diagnoses => :NEW.id_pat_history_diagnosis);
        END IF;
    END IF;
END A_IU_PAT_HISTORY_DIAGNOSIS;
-- CHANGE END:  Ana Rita Martins	