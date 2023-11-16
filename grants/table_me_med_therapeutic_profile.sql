-- Grant/Revoke object privileges 
grant select on ME_MED_THERAPEUTIC_PROFILE to ALERT_DEFAULT;
grant select, update, delete on ME_MED_THERAPEUTIC_PROFILE to ALERT_RESET;
grant select on ME_MED_THERAPEUTIC_PROFILE to ALERT_VIEWER;
grant select, insert, update, delete, references, alter, index on ME_MED_THERAPEUTIC_PROFILE to INTER_ALERT_V2;
