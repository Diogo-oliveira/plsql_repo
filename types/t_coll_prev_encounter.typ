CREATE OR REPLACE TYPE t_coll_prev_encounter AS table of t_rec_prev_encounter;


-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 02/12/2010 16:19
-- CHANGE REASON: [ALERT-146429] ddl.sql
drop type t_coll_prev_encounter
;
-- CHANGE END: Pedro Carneiro

-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 02/12/2010 16:20
-- CHANGE REASON: [ALERT-146429] ddl.sql
create or replace type t_coll_prev_encounter as table of t_rec_prev_encounter
;
-- CHANGE END: Pedro Carneiro