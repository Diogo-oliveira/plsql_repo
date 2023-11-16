-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 13/05/2013
-- CHANGE REASON: [ALERT-259146 ] Triage single page
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_data_blocks AS TABLE OF t_rec_data_blocks';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
--CHANGE END: Sofia Mendes