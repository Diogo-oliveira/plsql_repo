-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 19/12/2011 14:55
-- CHANGE REASON: [ALERT-207801] Reusability of documentation components in Touch-option templates
MERGE INTO doc_template_area_doc dtad
USING (SELECT id_doc_template, id_doc_area, id_documentation, rank
         FROM documentation
        WHERE id_doc_template IS NOT NULL
          AND id_doc_area IS NOT NULL) d
ON (dtad.id_doc_template = d.id_doc_template AND dtad.id_doc_area = d.id_doc_area AND dtad.id_documentation = d.id_documentation)
WHEN MATCHED THEN
    UPDATE
       SET dtad.rank = d.rank
WHEN NOT MATCHED THEN
    INSERT
        (dtad.id_doc_template, dtad.id_doc_area, dtad.id_documentation, dtad.rank)
    VALUES
        (d.id_doc_template, d.id_doc_area, d.id_documentation, d.rank);
-- CHANGE END: Ariel Machado