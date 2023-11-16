-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2009-APR-24
-- CHANGING REASON: novo record - medicação

create or replace type t_rec_take_type as object
(
  id number(24),
	label varchar2(4000),
	flg_default varchar2(1),
	default_qty number(24),
	id_advanced_input_field  number(24),
	rank  number(24)
);	
-- CHANGE END Patrícia Neto	