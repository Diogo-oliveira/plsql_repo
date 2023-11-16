CREATE OR REPLACE TRIGGER b_iu_advanced_directiv_inssft
    BEFORE INSERT OR UPDATE
    ON advanced_directive_inst_soft
    REFERENCING NEW AS NEW
    FOR EACH ROW
BEGIN
    :new.adw_last_update := sysdate;
END b_iu_advanced_directiv_inssft;
/
