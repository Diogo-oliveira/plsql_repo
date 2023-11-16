-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:32
-- CHANGE REASON: [ALERT-206286] 02_ALERT_DDLS
grant select on sys_message to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant select on sys_message to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2012-01-05
-- CHANGE REASON: SCH-6599 

GRANT select on sys_message to ALERT_BASECOMP;

-- CHANGE END: Bruno Martins

-- CHANGED BY: Joana Madureira Barroso
-- CHANGE DATE: 25/09/2014 16:24
-- CHANGE REASON: [ALERT-296372] 
GRANT select on alert.sys_message  TO alert_pharmacy_func;
-- CHANGE END: Joana Madureira Barroso


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SYS_MESSAGE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 22/03/2017 17:56
-- CHANGE REASON: [ALERT-329749] corrections
BEGIN
    pk_versioning.run('GRANT SELECT, REFERENCES ON sys_message TO alert_product_tr');
END;
/
-- CHANGE END: rui.mendonca