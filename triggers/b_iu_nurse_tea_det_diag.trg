CREATE OR REPLACE TRIGGER b_iu_nurse_tea_det_diag
  BEFORE INSERT OR UPDATE ON NURSE_TEA_DET_DIAG  
  FOR EACH ROW
DECLARE
BEGIN
    IF :new.id_diagnosis IS NOT NULL
    THEN
        :new.id_diag_inst_owner := 0;
    ELSE
        :new.id_diag_inst_owner := NULL;
    END IF;
END b_iu_nurse_tea_det_diag;
/