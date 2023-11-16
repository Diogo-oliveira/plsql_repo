-- CHANGED BY: Luís Maia
-- CHANGE DATE: 08/06/2011 16:36
-- CHANGE REASON: [ALERT-184131] New view for bed management
grant select on v_bed_occupation to intf_alert;
-- CHANGE END: Luís Maia


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 13/06/2011 17:28
-- CHANGE REASON: [ALERT-184134 ] Admission notes on Inpatient episode update not available
GRANT SELECT ON v_bed_occupation TO ALERT_INTER;
-- CHANGE END: Sofia Mendes