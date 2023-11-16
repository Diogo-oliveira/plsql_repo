-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2010-05-12
-- CHANGE REASON: ALERT-95774

grant select, references on market to alert_adtcod_cfg;

-- CHANGE END: Bruno Martins

grant select, references on ALERT.MARKET to alert_coding_mt;

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:57
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on MARKET to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on MARKET to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant select,references on market  to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant select,references on market  to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 04/05/2012 09:32
-- CHANGE REASON: [ALERT-229206] VERSIONING TERMINOLOGY SERVER - SCHEMA ALERT - GRANTS
GRANT SELECT ON ALERT.MARKET TO ALERT_CORE_DATA;
/
GRANT REFERENCES ON ALERT.MARKET TO ALERT_CORE_DATA;
/
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Nuno Alves
-- CHANGE DATE: 22/01/2015 23:05
-- CHANGE REASON: [ALERT-306018] ALERT-306018 Versioning Single Page backoffice
GRANT SELECT ON market to apex_alert_default;
/
-- CHANGE END: Nuno Alves