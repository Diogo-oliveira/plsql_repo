-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 07/04/2011 09:13
-- CHANGE REASON: [ALERT-159798] Be able to document PE according to E/M documentation guidelines
CREATE OR REPLACE PROCEDURE insert_into_template_system
(
    i_doc_template IN doc_template_system.id_doc_template%TYPE,
    i_doc_system   IN doc_template_system.id_doc_system%TYPE,
    i_available    IN doc_template_system.flg_available%TYPE DEFAULT 'Y'
) IS
BEGIN

    MERGE INTO doc_template_system t
    USING (SELECT i_doc_template id_doc_template, i_doc_system id_doc_system, i_available flg_available
             FROM dual) args
    ON (t.id_doc_template = args.id_doc_template AND t.id_doc_system = args.id_doc_system)
    WHEN MATCHED THEN
        UPDATE
           SET t.flg_available = nvl(args.flg_available, t.flg_available)
    WHEN NOT MATCHED THEN
        INSERT
            (id_doc_template, id_doc_system, flg_available)
        VALUES
            (args.id_doc_template, args.id_doc_system, args.flg_available);
END;
/
-- CHANGE END: Ariel Machado