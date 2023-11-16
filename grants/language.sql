-- CHANGED BY: Susana Silva
-- CHANGE DATE: 08/03/2010 10:38
-- CHANGE REASON: [ALERT-79827] 
grant select, references on LANGUAGE to alert_Default;
-- CHANGE END: Susana Silva

-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 21/12/2010 17:07
-- CHANGE REASON: [ALERT-151204] 
grant references on LANGUAGE to ALERT_DEFAULT;
-- CHANGE END:  Mauro Sousa

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:57
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant select on language to alert_inter;
grant references on LANGUAGE to alert_product_mt;
grant references on LANGUAGE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant select on language to alert_inter;
grant references on LANGUAGE to alert_product_mt;
grant references on LANGUAGE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on LANGUAGE to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant select on language to alert_inter;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 12:40
-- CHANGE REASON: [ALERT-206772] 
grant references, select on LANGUAGE to alert_product_mt;
grant references, select on LANGUAGE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- cmf 26-03-2012
grant select, references on alert.LANGUAGE to public;

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 04/05/2012 09:32
-- CHANGE REASON: [ALERT-229206] VERSIONING TERMINOLOGY SERVER - SCHEMA ALERT - GRANTS
GRANT SELECT ON ALERT.LANGUAGE TO ALERT_CORE_DATA;
/
GRANT REFERENCES ON ALERT.LANGUAGE TO ALERT_CORE_DATA;
/
-- CHANGE END: Alexandre Santos


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.LANGUAGE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
