-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: [ALERT-259146 ] Triage single page
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_pn_vs_viewer AS OBJECT
(
    id_pn_vs NUMBER(24),
    rank       NUMBER(6),
    id_group    varchar2(24 char),
    nr_records NUMBER(6),
    note_date timestamp(6) with local time zone
)';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
--CHANGE END: Sofia Mendes