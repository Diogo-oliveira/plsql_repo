-- Grant/Revoke object privileges 
grant select on THERAPEUTIC_PROFILE to ALERT_DEFAULT;
grant select, update, delete on THERAPEUTIC_PROFILE to ALERT_RESET;
grant select on THERAPEUTIC_PROFILE to ALERT_VIEWER;
grant select, insert, update, delete, references, alter, index on THERAPEUTIC_PROFILE to INTER_ALERT_V2;