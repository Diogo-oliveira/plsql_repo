-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 21/03/2012
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness / Current visit
BEGIN
    UPDATE task_timeline_ea tte
       SET tte.universal_desc_clob = to_clob(tte.universal_description)
     WHERE tte.universal_description IS NOT NULL
       AND (tte.universal_desc_clob IS NULL OR dbms_lob.compare(tte.universal_desc_clob, empty_clob()) = 0);

END;
/
--CHANGE END: Sofia Mendes
