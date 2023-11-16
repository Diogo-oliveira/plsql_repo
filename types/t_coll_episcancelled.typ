CREATE OR REPLACE TYPE t_coll_episcancelled AS TABLE OF t_rec_episcancelled
/

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 25-02-2010
-- CHANGE REASON: ALERT-69475
CREATE TYPE t_coll_episcancelled AS TABLE OF t_rec_episcancelled;
/
-- CHANGE END: Alexandre Santos