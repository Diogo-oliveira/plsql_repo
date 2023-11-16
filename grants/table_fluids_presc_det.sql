-- Grant/Revoke object privileges 
grant select, insert, update, delete, references, alter, index on fluids_presc_det to ALERT_DEMO;
grant select on FLUIDS_PRESC_DET to ALERT_VIEWER;
grant select on FLUIDS_PRESC_DET to INFARMED;
grant select on FLUIDS_PRESC_DET to INTER_ALERT_V2;