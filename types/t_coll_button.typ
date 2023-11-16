-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: ALERT-244590 Single page: change plan buttons ranks
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_button AS TABLE OF t_rec_button';
end;
/
--CHANGE END: Sofia Mendes