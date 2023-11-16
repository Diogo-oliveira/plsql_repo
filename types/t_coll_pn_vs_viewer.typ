-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: [ALERT-259146 ] Triage single page
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_pn_vs_viewer IS TABLE OF t_rec_pn_vs_viewer';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
--CHANGE END: Sofia Mendes