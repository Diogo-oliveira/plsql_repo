-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 25/02/2011 10:10
-- CHANGE REASON: [ALERT-164483] soap note blocks configuration types
CREATE OR REPLACE TYPE t_coll_template AS TABLE OF t_rec_template;
/
-- CHANGE END: Pedro Carneiro