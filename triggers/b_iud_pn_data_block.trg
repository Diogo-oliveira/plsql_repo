CREATE OR REPLACE TRIGGER b_iud_pn_data_block
    BEFORE DELETE OR INSERT OR UPDATE ON pn_data_block
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_pn_data_block      := 'PN_DATA_BLOCK.CODE_DATA_BLOCK.' || :NEW.id_pn_data_block;
        :NEW.code_pn_data_block_hist := 'PN_DATA_BLOCK.CODE_PN_DATA_BLOCK_HIST.' || :NEW.id_pn_data_block;
    ELSIF deleting
    THEN
        DELETE FROM translation t
         WHERE (t.code_translation = :OLD.code_pn_data_block OR t.code_translation = :OLD.code_pn_data_block_hist)
           AND t.code_translation LIKE 'PN\_DATA\_BLOCK.CODE\_%' ESCAPE '\';
    ELSIF updating
    THEN
        :NEW.code_pn_data_block      := 'PN_DATA_BLOCK.CODE_DATA_BLOCK.' || :OLD.id_pn_data_block;
        :NEW.code_pn_data_block_hist := 'PN_DATA_BLOCK.CODE_PN_DATA_BLOCK_HIST.' || :OLD.id_pn_data_block;
    END IF;
END b_iud_pn_data_block;
/
