-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 02/12/2010 16:16
-- CHANGE REASON: [ALERT-146429] ddl.sql
create or replace type t_coll_soap_block as table of t_rec_soap_block
;
-- CHANGE END: Pedro Carneiro