GRANT SELECT ON RESPONSE TO INTER_ALERT_V2;


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.RESPONSE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 14/06/2019 09:29
-- CHANGE REASON: [EMR-16972]
grant all on response to alert_inter;
-- CHANGE END: Pedro Henriques