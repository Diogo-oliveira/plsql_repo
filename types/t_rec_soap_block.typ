-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 02/12/2010 16:16
-- CHANGE REASON: [ALERT-146429] ddl.sql
create or replace type t_rec_soap_block as object
(
    id_block   number(24),
    desc_block varchar2(1000 char),
    flg_type   varchar2(1 char),
    rank       number(12)
)
;
-- CHANGE END: Pedro Carneiro