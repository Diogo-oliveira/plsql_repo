-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/May/2013
-- CHANGE REASON: ALERT-261290 Triage single page 
BEGIN
    --physical assessment
    --it is only registered by nurse
    UPDATE epis_documentation ed
       SET ed.id_doc_area = 5592
     WHERE ed.id_doc_area = 1045;

    UPDATE task_timeline_ea t
       SET t.id_doc_area = 5592
     WHERE t.id_doc_area = 1045;
END;
/
--END: Sofia Mendes
