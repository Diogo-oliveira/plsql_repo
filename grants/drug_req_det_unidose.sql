-- Grant/Revoke object privileges 
grant select on DRUG_REQ_DET_UNIDOSE to ALERT_VIEWER;
grant select, insert, update, delete, references, alter, index on DRUG_REQ_DET_UNIDOSE to INTER_ALERT_V2;
