CREATE OR REPLACE TRIGGER b_iu_pat_med_decl
  BEFORE INSERT OR UPDATE ON PAT_MED_DECL  
  FOR EACH ROW
DECLARE
BEGIN
    IF :new.id_diagnosis IS NOT NULL
    THEN
        :new.id_diag_inst_owner := 0;
    ELSE
        :new.id_diag_inst_owner := NULL;
    END IF;
END b_iu_pat_med_decl;
/