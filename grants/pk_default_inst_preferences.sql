-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 12/03/2012 09:55
-- CHANGE REASON: [ALERT-222674] 
grant execute on pk_default_inst_preferences to alert_viewer, alert_config;
-- CHANGE END:  Rui Gomes

-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 21/05/2013 16:58
-- CHANGE REASON: [ALERT-248672] new obj
grant execute on ALERT.PK_DEFAULT_INST_PREFERENCES to ALERT_INTER with grant option;
-- CHANGE END:  Rui Gomes


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant EXECUTE on ALERT.PK_DEFAULT_INST_PREFERENCES to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
