-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 10/07/2013 09:31
-- CHANGE REASON: [ALERT-261614] 
GRANT SELECT ON SEQ_REP_PREV_EPIS TO ALERT_VIEWER;
GRANT SELECT ON SEQ_REP_PREV_EPIS TO ALERT_CONFIG;

grant select, insert, update, delete on REP_PREV_EPIS to ALERT_CONFIG;
grant select on REP_PREV_EPIS to ALERT_DEFAULT;
grant select, update, delete on REP_PREV_EPIS to ALERT_RESET;
grant select, insert, update, delete on REP_PREV_EPIS to ALERT_SUPPORT;
grant select on REP_PREV_EPIS to ALERT_VIEWER;
grant select on REP_PREV_EPIS to DSV; 
-- CHANGE END: Tércio Soares