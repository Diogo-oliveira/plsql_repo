-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2009-APR-24
-- CHANGING REASON: novo record - medicação
create or replace type t_rec_dose as object
(
  qty number(24,4),
	unit_qty number(24),
	freq number(24,4),
	unit_freq number(24)
);
-- CHANGE END Patrícia Neto		