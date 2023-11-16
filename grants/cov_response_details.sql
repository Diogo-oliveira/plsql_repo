-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 03/07/2010 20:19
-- CHANGE REASON: [ALERT-109286] 
GRANT SELECT ON consult_req_hist TO alert_viewer;
GRANT ALTER,DELETE,INDEX,INSERT,REFERENCES,SELECT,UPDATE ON consult_req_hist TO inter_alert_v2;
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Ana Coelho
-- CHANGE DATE: 7-APR-2011
-- CHANGE REASON: ALERT-171286 
grant select, update, delete on ALERT.COV_RESPONSE_DETAILS to alert_reset;
-- CHANGE END: Ana Coelho