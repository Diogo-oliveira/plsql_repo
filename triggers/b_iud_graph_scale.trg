CREATE OR REPLACE
TRIGGER b_iud_graph_scale
    BEFORE DELETE OR INSERT OR UPDATE ON graph_scale
    FOR EACH ROW
BEGIN
    IF inserting
    THEN
        :NEW.code_graph_scale := 'GRAPH_SCALE.CODE_GRAPH_SCALE.' || :NEW.id_graph_scale;

    ELSIF deleting
    THEN
        DELETE FROM translation
         WHERE code_translation = :OLD.code_graph_scale;
    ELSIF updating
    THEN
        :NEW.code_graph_scale := 'GRAPH_SCALE.CODE_GRAPH_SCALE.' || :OLD.id_graph_scale;
    END IF;

END b_iud_graph_scale;
/
