-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 10/11/2010 12:21
-- CHANGE REASON: [ALERT-101505] 
grant references on TIMEZONE_REGION to ALERT_DEFAULT;
-- CHANGE END:  Mauro Sousa

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 23/08/2013 14:32
-- CHANGE REASON: [ALERT-263567] 
grant select on timezone_region to alert_core_Func;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 14/01/2014 11:44
-- CHANGE REASON: [ALERT-273757] 
grant select, references on timezone_region to alert_core_data;
-- CHANGE END: Rui Spratley