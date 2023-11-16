-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: [ALERT-259146 ] Triage single page
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_dblock_task_type AS table of t_rec_dblock_task_type';
end;
/
--CHANGE END: Sofia Mendes