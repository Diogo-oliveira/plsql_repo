-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 06/05/2011 11:28
-- CHANGE REASON: [ALERT-176644] cdr data model (changes_ddl.sql)
CREATE OR REPLACE TYPE t_coll_message AS TABLE OF t_rec_message;
-- CHANGE END: Pedro Carneiro