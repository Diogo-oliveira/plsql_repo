-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 19/12/2011 14:55
-- CHANGE REASON: [ALERT-207801] Reusability of documentation components in Touch-option templates
MERGE INTO doc_template_area dta
USING (SELECT DISTINCT id_doc_template, id_doc_area
         FROM documentation
        WHERE id_doc_template IS NOT NULL
          AND id_doc_area IS NOT NULL) d
ON (dta.id_doc_template = d.id_doc_template AND dta.id_doc_area = d.id_doc_area)
WHEN MATCHED THEN
    UPDATE
       SET dta.action_subject = 'DOC_TEMPLATE_AREA.ACTION_SUBJECT.' || d.id_doc_template || '.' || d.id_doc_area
WHEN NOT MATCHED THEN
    INSERT
        (dta.id_doc_template, dta.id_doc_area, dta.action_subject)
    VALUES
        (d.id_doc_template,
         d.id_doc_area,
         'DOC_TEMPLATE_AREA.ACTION_SUBJECT.' || d.id_doc_template || '.' || d.id_doc_area);
-- CHANGE END: Ariel Machado