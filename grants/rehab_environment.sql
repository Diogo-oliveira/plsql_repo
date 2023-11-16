-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 04/03/2011 17:16
-- CHANGE REASON: [ALERT-165407] 
begin
-- Grant/Revoke object privileges 
grant select, insert, update, delete on REHAB_ENVIRONMENT to ALERT_CONFIG;
grant select on REHAB_ENVIRONMENT to ALERT_DEFAULT;
grant select on REHAB_ENVIRONMENT to ALERT_REPORTS;
grant select, update, delete on REHAB_ENVIRONMENT to ALERT_RESET;
grant select, insert, update, delete on REHAB_ENVIRONMENT to ALERT_SUPPORT;
grant select, insert, update, delete, references, alter, index on REHAB_ENVIRONMENT to ALERT_SYS;
grant select on REHAB_ENVIRONMENT to ALERT_VIEWER;
grant select on REHAB_ENVIRONMENT to ALERT_VIEWER_TEMP;
grant select on REHAB_ENVIRONMENT to DSV;
grant select, insert, update, delete, references, alter, index on REHAB_ENVIRONMENT to INTER_ALERT_V2;
end;
/
-- CHANGE END:  Nuno Neves


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.REHAB_ENVIRONMENT to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
