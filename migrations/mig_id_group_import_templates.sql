-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/May/2013
-- CHANGE REASON: ALERT-261290 Triage single page 
BEGIN
    UPDATE epis_pn_det_task e
       SET e.id_group_import =
           (SELECT ed.id_doc_area
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = e.id_task)
     WHERE e.id_task_type = 36
       AND e.id_group_import IS NULL;
END;
/
--END: Sofia Mendes
