-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 09/12/2013 14:07
-- CHANGE REASON: [ALERT-271432] 
grant select on codification_relations to alert_core_func;
grant select on codification_relations to alert_core_data with grant option;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Nuno Gomes
-- CHANGE DATE: 15/01/2014
-- CHANGE REASON: CODING-1637
grant select, references on codification_relations to alert_coding_mt;
grant select, references on codification_relations to alert_coding_tr;
-- CHANGE END: Nuno Gomes

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 26/02/2014 12:04
-- CHANGE REASON: [CODING-1844] 
grant select, references on codification_relations to alert_core_data with grant option;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Daniel Ferreira
-- CHANGE DATE: 25/06/2014 14:25
-- CHANGE REASON: [CODING-2124]
GRANT SELECT, REFERENCES ON ALERT.CODIFICATION_RELATIONS TO ALERT_CODING_MT WITH GRANT OPTION;
-- CHANGE END: Daniel Ferreira