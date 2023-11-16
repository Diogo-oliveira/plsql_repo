-- CHANGED BY: Joana Barroso
-- CHANGE DATE: 23/12/2009 16:59
-- CHANGE REASON: [ALERT-63465] 
GRANT SELECT ON ALERT.REF_MAP TO INTER_ALERT_V2;
GRANT SELECT ON ALERT.REF_MAP TO INTF_ALERT;
-- CHANGE END: Joana Barroso

-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 25/08/2011 16:32
-- CHANGE REASON: [ALERT-191644] An error is displayed while executing the reset. Child record found for SCHEDULE table.
GRANT SELECT, UPDATE, DELETE ON ref_map TO alert_reset;
-- CHANGE END: Ariel Machado
