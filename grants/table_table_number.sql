GRANT EXECUTE ON table_table_number TO INTF_ALERT; 


-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant execute on TABLE_TABLE_NUMBER to ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant EXECUTE on ALERT.TABLE_TABLE_NUMBER to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 09/01/2018 16:30
-- CHANGE REASON: [ALERT-334916 ] Dispensation action per time interval
BEGIN
    pk_versioning.run('grant execute on TABLE_TABLE_NUMBER to ALERT_PHARMACY_FUNC');
END;
/
-- CHANGE END: Sofia Mendes