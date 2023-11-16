CREATE OR REPLACE TRIGGER b_iu_pat_advanced_directive_dt
    BEFORE INSERT OR UPDATE
    ON pat_advanced_directive_det
    REFERENCING NEW AS NEW
    FOR EACH ROW
BEGIN
    :new.adw_last_update := sysdate;
END b_iu_pat_advanced_directive_dt;
/
