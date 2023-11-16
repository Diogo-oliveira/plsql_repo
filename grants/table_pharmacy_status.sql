-- Grant/Revoke object privileges 
grant select, insert, update, delete, references, alter, index on PHARMACY_STATUS to ALERT_DEMO;
grant select on PHARMACY_STATUS to ALERT_VIEWER;
grant select on PHARMACY_STATUS to INFARMED;
grant select on PHARMACY_STATUS to INTER_ALERT_V2;