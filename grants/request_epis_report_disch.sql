-- Grant/Revoke object privileges 
grant select on REQUEST_EPIS_REPORT_DISCH to ALERT_DEFAULT;
grant select, update, delete on REQUEST_EPIS_REPORT_DISCH to ALERT_RESET;
grant select, insert, update, delete on REQUEST_EPIS_REPORT_DISCH to ALERT_SUPPORT;
grant select, update on REQUEST_EPIS_REPORT_DISCH to ALERT_VIEWER;
grant select, update on REQUEST_EPIS_REPORT_DISCH to ALERT_VIEWER_TEMP;
grant select on REQUEST_EPIS_REPORT_DISCH to DSV;
grant select, insert, update, delete, references, alter, index on REQUEST_EPIS_REPORT_DISCH to INTER_ALERT_V2;
