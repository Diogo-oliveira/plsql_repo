-- CHANGED BY: Telmo
-- CHANGE DATE: 26-11-2010
-- CHANGE REASON: SCH-3434
grant select on alert.institution to alert_apsschdlr_tr;
-- CHANGE END: Telmo
grant select, references on ALERT.INSTITUTION to alert_coding_mt;


-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:58
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on INSTITUTION to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references,select on INSTITUTION to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- cmf 09-04-2012
grant select on INSTITUTION to public;

-- cmf 13-04-2012
grant references on institution to public;

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 04/05/2012 09:32
-- CHANGE REASON: [ALERT-229206] VERSIONING TERMINOLOGY SERVER - SCHEMA ALERT - GRANTS
GRANT SELECT ON ALERT.INSTITUTION TO ALERT_CORE_DATA;
/
GRANT REFERENCES ON ALERT.INSTITUTION TO ALERT_CORE_DATA;
/
-- CHANGE END: Alexandre Santos

-- CHANGED BY: cristina.oliveira
-- CHANGE DATE: 19/01/2018 16:02
-- CHANGE REASON: [ALERT-335179 ] 
BEGIN
    pk_versioning.run('GRANT REFERENCES, SELECT ON institution TO alert_pharmacy_data WITH GRANT OPTION');
END;
/
-- CHANGE END: cristina.oliveira