-- CHANGED BY:  Gisela Couto
-- CHANGE DATE: 16/06/2014 18:21
-- CHANGE REASON: [ALERT-286096] Dev DB - CDA Section: Medication allergies
begin
pk_versioning.run('GRANT EXECUTE ON T_TAB_ALLERGIES_CDAS_NEW TO alert_inter');
end;
/
-- CHANGE END:  Gisela Couto