-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 06/05/2011 11:27
-- CHANGE REASON: [ALERT-176644] cdr data model (changes_ddl.sql)
CREATE OR REPLACE TYPE t_coll_cdr_out AS TABLE OF t_rec_cdr_out;
-- CHANGE END: Pedro Carneiro