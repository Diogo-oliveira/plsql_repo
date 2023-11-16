-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:58
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on EPISODE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on EPISODE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on INSTITUTION to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 14:42
-- CHANGE REASON: [ALERT-206805] 
GRANT REFERENCES,SELECT ON EPISODE TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro


GRANT SELECT ON ALERT.EPISODE TO ALERT_PRODUCT_TR;

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 05/12/2013 18:14
-- CHANGE REASON: [ALERT-271069] 
grant select, references on alert.episode to alert_core_Data;
-- CHANGE END: Rui Spratley


-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 14/03/2014 11:58
-- CHANGE REASON: [ALERT-279114] 
GRANT SELECT ON alert.episode TO alert_product_tr WITH GRANT OPTION;
-- CHANGE END: Alexis Nascimento

-- CHANGED BY: Miguel Gomes 
-- CHANGE DATE: 21/07/2014 
-- CHANGE REASON: [ALERT-291054 ]  
GRANT SELECT ON EPISODE TO ALERT_PDMS_TR WITH GRANT OPTION; 
-- CHANGE END: Miguel Gomes 



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.EPISODE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- cmf 14-03-2017
BEGIN
    pk_versioning.run('GRANT SELECT ON episode TO alert_pharmacy_func');
END;
/


-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 12/01/2018 16:46
-- CHANGE REASON: [ALERT-335041] Dispense action per time interval
BEGIN
    pk_versioning.run('GRANT SELECT, REFERENCES ON episode TO alert_pharmacy_data');
END;
/
-- CHANGE END: rui.mendonca