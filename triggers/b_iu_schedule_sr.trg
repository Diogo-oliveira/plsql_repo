CREATE OR REPLACE TRIGGER b_iu_schedule_sr
  BEFORE INSERT OR UPDATE ON SCHEDULE_SR  
  FOR EACH ROW
DECLARE
BEGIN
    IF :new.id_diagnosis IS NOT NULL
    THEN
        :new.id_diag_inst_owner := 0;
    ELSE
        :new.id_diag_inst_owner := NULL;
    END IF;
END b_iu_schedule_sr;
/