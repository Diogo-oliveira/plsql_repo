-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 18-09-2018
-- CHANGE REASON: ALERT-69475
drop type t_coll_patcriteriaactiveclin;
create or replace type t_coll_patcriteriaactiveclin as table of t_rec_patcriteriaactiveclin;

-- CHANGE END: Pedro Henriques