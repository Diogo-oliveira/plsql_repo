-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/02/2012
-- CHANGE REASON: [ALERT-166586] Change database model - EDIS restructuring - Present Illness
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_area AS TABLE OF t_rec_area';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
--CHANGE END: Sofia Mendes

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 11/09/2014 14:58
-- CHANGE REASON: [ALERT-295101] 
drop type t_coll_area;
/
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 11/09/2014 14:59
-- CHANGE REASON: [ALERT-295101] 
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_coll_area AS TABLE OF t_rec_area';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
-- CHANGE END: Paulo Teixeira