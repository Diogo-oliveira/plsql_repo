CREATE OR REPLACE TRIGGER b_iu_discharge_detail
  BEFORE INSERT OR UPDATE ON DISCHARGE_DETAIL  
  FOR EACH ROW
DECLARE
BEGIN
    IF :new.id_transfer_diagnosis IS NOT NULL
    THEN
        :new.id_diag_inst_owner := 0;
    ELSE
        :new.id_diag_inst_owner := NULL;
    END IF;
END b_iu_discharge_detail;
/