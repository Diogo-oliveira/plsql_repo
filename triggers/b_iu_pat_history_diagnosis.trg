CREATE OR REPLACE TRIGGER b_iu_pat_history_diagnosis
  BEFORE INSERT OR UPDATE ON PAT_HISTORY_DIAGNOSIS  
  FOR EACH ROW
DECLARE
BEGIN
    IF :new.id_diagnosis IS NOT NULL
    THEN
        :new.id_diag_inst_owner := 0;
    ELSE
        :new.id_diag_inst_owner := NULL;
    END IF;
    IF :new.id_alert_diagnosis IS NOT NULL
    THEN
        :new.id_adiag_inst_owner := 0;
    ELSE
        :new.id_adiag_inst_owner := NULL;
    END IF;
END b_iu_pat_history_diagnosis;
/