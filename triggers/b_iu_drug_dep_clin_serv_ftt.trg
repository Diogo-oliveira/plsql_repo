CREATE OR REPLACE TRIGGER b_iu_drug_dep_clin_serv
    BEFORE INSERT OR UPDATE ON ALERT.drug_dep_clin_serv
    FOR EACH ROW
BEGIN

    IF :NEW.flg_take_type IS NULL
       AND :NEW.id_software = 8
    THEN

        :NEW.flg_take_type := 'U';

    END IF;

EXCEPTION
    WHEN OTHERS THEN
        alertlog.pk_alertlog.log_error('B_IU_DRUG_DEP_CLIN_SERV-' || SQLERRM);

END b_iu_drug_dep_clin_serv;
/
