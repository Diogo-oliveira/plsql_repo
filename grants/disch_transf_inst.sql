-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 25/03/2010 09:32
-- CHANGE REASON: [ALERT-83163] 
GRANT SELECT ON ALERT.DISCH_TRANSF_INST TO PUBLIC;
GRANT SELECT ON ALERT.DISCH_TRANSF_INST TO INTER_ALERT_V2;
GRANT SELECT ON ALERT.DISCH_TRANSF_INST TO PIX;
GRANT SELECT ON ALERT.DISCH_TRANSF_INST TO ALERT_VIEWER;
-- CHANGE END: Pedro Teixeira



-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 25/03/2010 09:32
-- CHANGE REASON: [ALERT-83163] 
GRANT SELECT ON ALERT.DISCH_TRANSF_INST TO PUBLIC;
GRANT SELECT ON ALERT.DISCH_TRANSF_INST TO INTER_ALERT_V2;
GRANT SELECT ON ALERT.DISCH_TRANSF_INST TO ALERT_VIEWER;
-- CHANGE END: Pedro Teixeira

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.DISCH_TRANSF_INST to alert_reset;
-- CHANGE END: Ana Coelho