-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 24/10/2017
grant select on epis_doc_delivery  TO alert_inter;
-- CHANGE END: Diogo Oliveira

-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 18/05/2018 11:52
-- CHANGE REASON: [EMR-3545] Grants to ADT
grant select on epis_doc_delivery to ALERT_ADTCOD_CFG;
grant select on epis_doc_delivery to ALERT_ADTCOD; 
-- CHANGE END: Elisabete Bugalho