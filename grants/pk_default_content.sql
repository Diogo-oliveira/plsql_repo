-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 23/03/2011 17:29
-- CHANGE REASON: [ALERT-167568] 
grant execute on Pk_Default_Content to ALERT_CONFIG;
grant execute on Pk_Default_Content to ALERT;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 11/04/2011 17:17
-- CHANGE REASON: [ALERT-171940] 
grant execute on Pk_Default_Content to ALERT_CONFIG;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 21/05/2013 16:58
-- CHANGE REASON: [ALERT-248672] new obj
grant execute on ALERT.PK_DEFAULT_CONTENT to ALERT_INTER with grant option;
-- CHANGE END:  Rui Gomes


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant EXECUTE on ALERT.PK_DEFAULT_CONTENT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
