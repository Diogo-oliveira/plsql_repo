-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 04/03/2011 17:29
-- CHANGE REASON: [ALERT-165407] 
begin
-- Grant/Revoke object privileges 
grant select, insert, update, delete on REHAB_ENVIRONMENT_PROF to ALERT_CONFIG;
grant select on REHAB_ENVIRONMENT_PROF to ALERT_DEFAULT;
grant select on REHAB_ENVIRONMENT_PROF to ALERT_REPORTS;
grant select, update, delete on REHAB_ENVIRONMENT_PROF to ALERT_RESET;
grant select, insert, update, delete on REHAB_ENVIRONMENT_PROF to ALERT_SUPPORT;
grant select, insert, update, delete, references, alter, index on REHAB_ENVIRONMENT_PROF to ALERT_SYS;
grant select on REHAB_ENVIRONMENT_PROF to ALERT_VIEWER;
grant select on REHAB_ENVIRONMENT_PROF to ALERT_VIEWER_TEMP;
grant select on REHAB_ENVIRONMENT_PROF to DSV;
grant select, insert, update, delete, references, alter, index on REHAB_ENVIRONMENT_PROF to INTER_ALERT_V2;
end;
/
-- CHANGE END:  Nuno Neves