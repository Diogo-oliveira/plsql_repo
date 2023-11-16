-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 28/11/2013 10:41
-- CHANGE REASON: [ALERT-270757] Medication Events DDL
GRANT SELECT ON institution_language TO alert_product_tr;
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 28/11/2013 10:41
-- CHANGE REASON: [ALERT-270757] Medication Events DDL
GRANT SELECT ON institution_language TO alert_product_tr with grant option;
-- CHANGE END: Gustavo Serrano


-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 07/05/2014 09:01
-- CHANGE REASON: [ALERT-283775] 
grant select on institution_language to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY:  Katia Marques
-- CHANGE DATE: 12/06/2014 12:03
-- CHANGE REASON: [SCH-9021] 
GRANT select on institution_language to ALERT_APSSCHDLR_TR;
-- CHANGE END:  Katia Marques

-- CHANGED BY:  Katia Marques
-- CHANGE DATE: 12/06/2014 12:03
-- CHANGE REASON: [SCH-9021] 
GRANT select on institution_language to ALERT_APSSCHDLR_MT;
-- CHANGE END:  Katia Marques

-- CHANGED BY:  Luis Fernandes
-- CHANGE DATE: 12/06/2014 12:03
-- CHANGE REASON: ALERT-331948
GRANT select on institution_language to ALERT_APEX_TOOLS_CONTENT;
-- CHANGE END:  Luis Fernandes

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 15/07/2022 10:20
-- CHANGE REASON: [EMR-54070] - Need for prescription validation information
GRANT SELECT ON institution_language TO alert_pharmacy_data with grant option;
-- CHANGE END: Cristina Oliveira