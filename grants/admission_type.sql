grant select on admission_type to alert_viewer;


-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 10/11/2010 12:32
-- CHANGE REASON: [ALERT-101505] 
grant references on ADMISSION_TYPE to ALERT_DEFAULT;
-- CHANGE END:  Mauro Sousa