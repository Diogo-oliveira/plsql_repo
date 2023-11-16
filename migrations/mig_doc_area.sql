-- CHANGED BY: António Neto
-- CHANGE DATE: 27/04/2011 10:50
-- CHANGE REASON: [ALERT-174852] Fill the field doc_area.code_doc_area - INP - H&P import screen - Assessment tools - No descriptives available (only registration date/time).

BEGIN
    FOR item IN (SELECT da.id_doc_area
                   FROM doc_area da
                  WHERE da.code_doc_area IS NULL
                     OR da.code_doc_area <> 'DOC_AREA.CODE_DOC_AREA.' || da.id_doc_area)
    LOOP
        update doc_area da set da.code_doc_area = 'DOC_AREA.CODE_DOC_AREA.' || item.id_doc_area  where da.id_doc_area = item.id_doc_area;
    END LOOP;
END;
/

-- CHANGE END: António Neto
